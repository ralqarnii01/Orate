//
//  Record.swift
//  Orate
//

import SwiftUI
import AVFoundation
import Vision
import Speech
import Combine
import NaturalLanguage

// MARK: - 1. Tutorial Data Model
struct TutorialStep: Identifiable {
    let id: Int
    let stepText: String
    let iconName: String
    let title: String
    let description: String
}

let tutorialSteps: [TutorialStep] = [
    TutorialStep(id: 1, stepText: "1/3", iconName: "camera", title: "Angle & Framing", description: "Keep your phone at eye level. Face, shoulders and hands in frame."),
    TutorialStep(id: 2, stepText: "2/3", iconName: "sun.max", title: "Light up your face", description: "Face a soft, even light source. Avoid dark backgrounds."),
    TutorialStep(id: 3, stepText: "3/3", iconName: "mic", title: "Speak Clearly", description: "Ensure minimal background noise for accurate transcription.")
]

// MARK: - 2. Camera, Speech & Vision Manager
class CameraManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var session = AVCaptureSession()
    @Published var isRecording = false
    @Published var recordingTime = "00:00"
    @Published var activeResult: AIAnalysisResult?
    @Published var isAnalyzing = false

    /// Called on the main queue once the recording is on disk, with nil when
    /// nothing usable was written. Lets the backend upload start after the
    /// camera screen has already navigated away.
    var onRecordingFinished: ((URL?) -> Void)?

    private var totalFrames = 0
    private var lookedAwayFrames = 0
    private var handMovedFrames = 0
    private var smileFrames = 0
    private nonisolated(unsafe) var frameSkipCount = 0
    
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var timer: Timer?
    private var secondsElapsed = 0
    
    private let sessionQueue = DispatchQueue(label: "orate.camera.sessionQueue")
    private var isConfigured = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    override init() {
        super.init()
        if !isPreview {
            checkPermissions()
        }
    }

    func checkPermissions() {
        guard !isPreview else { return }
        
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted { self.setupCamera() }
        }
    }

    func setupCamera() {
        guard !isPreview else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isConfigured else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                      ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                      ?? AVCaptureDevice.default(for: .video)

            guard let videoDevice = device,
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
                if self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                }
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            if self.session.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.setSampleBufferDelegate(
                    self,
                    queue: DispatchQueue(label: "orate.videoFrameQueue")
                )
                self.session.addOutput(self.videoDataOutput)
            }

            self.session.commitConfiguration()
            self.isConfigured = true

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        Task { @MainActor in
            guard self.isRecording else { return }
            self.totalFrames += 1
            self.frameSkipCount += 1
        }

        // Throttle Vision ML to run every 6 frames (~5 FPS) for smooth performance
        guard frameSkipCount % 6 == 0 else { return }

        var requests: [VNRequest] = []

        let faceRequest = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self = self, let results = request.results as? [VNFaceObservation] else { return }
            for face in results {
                if let yaw = face.yaw?.doubleValue, abs(yaw) > 0.30 {
                    Task { @MainActor in self.lookedAwayFrames += 1 }
                }
                
                if let mouth = face.landmarks?.outerLips {
                    let points = mouth.normalizedPoints
                    if points.count > 6 {
                        let width = abs(points[0].x - points[6].x)
                        if width > 0.18 {
                            Task { @MainActor in self.smileFrames += 1 }
                        }
                    }
                }
            }
        }
        requests.append(faceRequest)

        let bodyPoseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let self = self, let results = request.results as? [VNHumanBodyPoseObservation] else { return }
            for pose in results {
                let leftWrist = try? pose.recognizedPoint(.leftWrist)
                let rightWrist = try? pose.recognizedPoint(.rightWrist)
                
                if (leftWrist?.confidence ?? 0) > 0.25 || (rightWrist?.confidence ?? 0) > 0.25 {
                    Task { @MainActor in self.handMovedFrames += 1 }
                }
            }
        }
        requests.append(bodyPoseRequest)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform(requests)
    }

    func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        totalFrames = 0
        lookedAwayFrames = 0
        handMovedFrames = 0
        smileFrames = 0
        frameSkipCount = 0

        let outputPath = NSTemporaryDirectory().appending("output.mov")
        let outputURL = URL(fileURLWithPath: outputPath)

        if FileManager.default.fileExists(atPath: outputPath) {
            try? FileManager.default.removeItem(atPath: outputPath)
        }

        let videoConnection = movieOutput.connection(with: .video)
        guard !isPreview,
              let connection = videoConnection,
              connection.isActive,
              connection.isEnabled else {
            isRecording = true
            startTimer()
            return
        }

        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        } else {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        startTimer()
    }

    private func stopRecording() {
        stopTimer()
        isRecording = false
        isAnalyzing = true

        if !isPreview && movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // No camera (Simulator/preview): there is no file to upload.
                self.onRecordingFinished?(nil)
                let dummyURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("output.mov"))
                self.finalizeAnalysis(transcript: "", url: dummyURL)
            }
        }
    }

    /// Releases the capture session once its recording has been handed over.
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func startTimer() {
        secondsElapsed = 0
        recordingTime = "00:00"
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsElapsed += 1
            let minutes = self.secondsElapsed / 60
            let seconds = self.secondsElapsed % 60
            self.recordingTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // AVFoundation can report an error and still leave a playable file, so
        // trust the file on disk rather than the error alone.
        let attributes = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path)
        let byteCount = (attributes?[.size] as? NSNumber)?.intValue ?? 0

        DispatchQueue.main.async {
            self.onRecordingFinished?(byteCount > 0 ? outputFileURL : nil)
        }

        processRecordedAudio(url: outputFileURL)
    }

    private func processRecordedAudio(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            DispatchQueue.main.async { self.finalizeAnalysis(transcript: "", url: url) }
            return
        }

        guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
            DispatchQueue.main.async { self.finalizeAnalysis(transcript: "", url: url) }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        request.contextualStrings = [
            "um", "uh", "like", "you know", "basically",
            "actually", "so", "literally", "right", "honestly"
        ]
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcriptText = result.bestTranscription.formattedString
                if result.isFinal || !transcriptText.isEmpty {
                    self.finalizeAnalysis(transcript: transcriptText, url: url)
                    return
                }
            }
            
            if error != nil {
                self.finalizeAnalysis(transcript: "", url: url)
            }
        }
    }

    // دالة حساب عدد الجمل بدقة عالية
    private func countSentences(in text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = trimmed
        var count = 0
        tokenizer.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }

    private func finalizeAnalysis(transcript: String, url: URL) {
        let sentenceCount = countSentences(in: transcript)
        
        // -----------------------------------------------------------------
        // شرط صارم: إذا لم يتوفر حديث أو كان عدد الجمل أقل من أو يساوي 3 -> صفّر التقييم
        // -----------------------------------------------------------------
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sentenceCount <= 2 {
            let zeroResult = AIAnalysisResult(
                overallScore: 0,
                transcript: transcript.isEmpty ? "No speech detected in session." : transcript,
                speakingPaceWPM: 0,
                paceFeedback: "No Speech Detected",
                eyeContactScore: 0,
                eyeContactFeedback: "Session incomplete",
                handMovementScore: 0,
                handMovementFeedback: "Session incomplete",
                fillerWords: [],
                wordReplacements: [],
                overallFeedback: "Speech was too short for evaluation. Please speak at least 4 full sentences.",
                strengthsFeedback: "N/A",
                growthFeedback: "Speak for a longer duration to receive speech",
                actionableTip: "Aim to present at least 4 complete sentences during practice."
            )
            
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.activeResult = zeroResult
            }
            return
        }

        // -----------------------------------------------------------------
        // التقييم الاعتيادي في حال تجاوز 3 جمل
        // -----------------------------------------------------------------
        let safeTotal = max(1, totalFrames)
        
        let rawEyePct = max(0, min(100, Int(((Double(safeTotal - lookedAwayFrames) / Double(safeTotal)) * 100))))
        let eyePoints = (Double(rawEyePct) / 100.0) * 25.0

        let rawGesturePct = max(0, min(100, Int(((Double(handMovedFrames) / Double(safeTotal)) * 100))))
        let bodyPoints = min(25.0, (Double(rawGesturePct) / 20.0) * 25.0)

        let wordsCount = transcript.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let durationMin = max(0.1, Double(secondsElapsed) / 60.0)
        let wpm = wordsCount > 0 ? Int(Double(wordsCount) / durationMin) : 0

        let pacePoints: Double
        let pacingStatus: String
        let pacingAdvice: String

        switch wpm {
        case 110...155:
            pacePoints = 25.0
            pacingStatus = "Optimal pace (\(wpm) WPM)"
            pacingAdvice = "Your tempo is in the 110–155 WPM sweet spot! Excellent engagement."
        case 90...109:
            pacePoints = 18.0
            pacingStatus = "Slightly slow (\(wpm) WPM)"
            pacingAdvice = "Target 110–155 WPM. Speak slightly faster to hold engagement."
        case 156...175:
            pacePoints = 18.0
            pacingStatus = "Slightly fast (\(wpm) WPM)"
            pacingAdvice = "Target 110–155 WPM. Insert brief pauses after main points."
        default:
            pacePoints = 10.0
            pacingStatus = wpm < 90 ? "Too slow (\(wpm) WPM)" : "Too fast (\(wpm) WPM)"
            pacingAdvice = "Target 110–155 WPM. Adjusting speed helps listener retention."
        }

        let cleanedTranscript = transcript.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined(separator: " ")

        let targetFillers = ["um", "uh", "like", "you know", "basically", "actually", "so", "literally", "right", "honestly"]
        var detectedFillers: [FillerWord] = []

        if !cleanedTranscript.isEmpty {
            for filler in targetFillers {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: filler))\\b"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let count = regex.numberOfMatches(in: cleanedTranscript, range: NSRange(location: 0, length: cleanedTranscript.utf16.count))
                    if count > 0 {
                        detectedFillers.append(FillerWord(word: filler, count: count))
                    }
                }
            }
        }

        let totalFillerCount = detectedFillers.reduce(0) { $0 + $1.count }
        let fillerPoints = max(0.0, 25.0 - (Double(totalFillerCount) * 3.0))

        let totalScore = Int(pacePoints + eyePoints + bodyPoints + fillerPoints)

        var suggestions: [WordReplacement] = []
        if cleanedTranscript.contains("like") { suggestions.append(WordReplacement(original: "like", replacement: "such as")) }
        if cleanedTranscript.contains("you know") { suggestions.append(WordReplacement(original: "you know", replacement: "as you may know")) }
        if cleanedTranscript.contains("basically") { suggestions.append(WordReplacement(original: "basically", replacement: "in essence")) }

        let strengths = eyePoints >= 18 ? "Maintained strong eye contact with the camera." : "Pacing was steady and readable."
        let growth = totalFillerCount > 2 ? "Reduce filler word usage ('um', 'uh', 'like')." : "Try incorporating more body language."
        let drill = totalFillerCount > 0 ? "Pause silently for 2 seconds whenever you feel the urge to say 'um'." : "Keep your eyes locked onto the camera lens."

        let finalResult = AIAnalysisResult(
            overallScore: max(0, min(100, totalScore)),
            transcript: transcript,
            speakingPaceWPM: wpm,
            paceFeedback: pacingStatus,
            eyeContactScore: rawEyePct,
            eyeContactFeedback: eyePoints >= 18 ? "High engagement maintained" : "Focus directly on the camera lens",
            handMovementScore: rawGesturePct,
            handMovementFeedback: bodyPoints >= 18 ? "Natural body gesture usage" : "Incorporate hand gestures to emphasize points",
            fillerWords: detectedFillers,
            wordReplacements: suggestions,
            overallFeedback: pacingAdvice,
            strengthsFeedback: strengths,
            growthFeedback: growth,
            actionableTip: drill
        )

        DispatchQueue.main.async {
            self.isAnalyzing = false
            self.activeResult = finalResult
        }
    }
}

// MARK: - 3. Camera Preview
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.videoPreviewLayer.frame = uiView.bounds
    }
}

// MARK: - 4. Analyzing Screen View
struct AnalyzingView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var activeDot = 0

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color(red: 0.98, green: 0.82, blue: 0.88))
                    .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.width * 0.22)

                Circle()
                    .fill(Color(red: 0.80, green: 0.95, blue: 0.94))
                    .frame(width: geo.size.width * 0.85, height: geo.size.width * 0.85)
                    .offset(x: -geo.size.width * 0.38, y: geo.size.height - (geo.size.width * 0.45))
            }
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.65, blue: 0.78))
                        .frame(width: 16, height: 16)
                        .offset(x: -80, y: 40)

                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.15))
                        .offset(x: 72, y: -54)

                    ZStack {
                        Image(systemName: "bubble.left.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 140)
                            .foregroundColor(Color(red: 0.32, green: 0.80, blue: 0.78))

                        VStack(spacing: 5) {
                            HStack(spacing: 22) {
                                Circle().fill(Color.black).frame(width: 8, height: 8)
                                Circle().fill(Color.black).frame(width: 8, height: 8)
                            }
                            
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addQuadCurve(to: CGPoint(x: 18, y: 0), control: CGPoint(x: 9, y: 10))
                            }
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 18, height: 8)
                        }
                        .offset(x: -4, y: -8)

                        Path { path in
                            path.move(to: CGPoint(x: 22, y: 80))
                            path.addLine(to: CGPoint(x: 10, y: 95))
                            path.move(to: CGPoint(x: 130, y: 70))
                            path.addLine(to: CGPoint(x: 146, y: 42))
                            path.move(to: CGPoint(x: 58, y: 132))
                            path.addLine(to: CGPoint(x: 58, y: 152))
                            path.move(to: CGPoint(x: 92, y: 132))
                            path.addLine(to: CGPoint(x: 92, y: 152))
                        }
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 150, height: 155)

                        HStack(spacing: 26) {
                            Capsule().fill(Color.black).frame(width: 18, height: 7)
                            Capsule().fill(Color.black).frame(width: 18, height: 7)
                        }
                        .offset(x: -2, y: 76)
                    }
                }
                .scaleEffect(1.4)
                .scaleEffect(pulseScale)

                VStack(spacing: 12) {
                    Text("Analyzing your practice")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.85))

                    Text("Listening to your voice and analyzing your\nbody language...")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(red: 0.60, green: 0.50, blue: 0.95).opacity(activeDot == index ? 1.0 : 0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(activeDot == index ? 1.45 : 1.0)
                    }
                }
                .padding(.top, 6)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeDot = (activeDot + 1) % 3
                }
            }
        }
    }
}

// MARK: - 5. Main Camera View Full Screen
struct CameraTutorialView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var analysis: SpeechAnalysisViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var cameraManager = CameraManager()
    @State private var currentStepIndex = 0
    @State private var isRecordingPage = false
    
    private var isPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        ZStack {
            if cameraManager.isAnalyzing {
                AnalyzingView()
                    .transition(.opacity)
            } else {
                if isPreviewMode {
                    Color.gray.opacity(0.3)
                        .ignoresSafeArea()
                } else {
                    CameraPreview(cameraManager: cameraManager)
                        .ignoresSafeArea()
                }
                
                VStack {
                    topNavigationBar
                    
                    Spacer()
                    
                    if isRecordingPage {
                        recordingControlView
                    } else {
                        stepCardView
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear { cameraManager.setupCamera() }
    }
    
    private var topNavigationBar: some View {
        HStack {
            Button(action: { router.currentScreen = .practice }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.oratePrimaryText)
                    .padding(10)
                    .background(Circle().fill(colorScheme == .dark ? Color.clear : Color.orateCardBackground.opacity(0.8)))
            }
            .modifier(RecordCircleGlassStyle(colorScheme: colorScheme))
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(cameraManager.recordingTime)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(colorScheme == .dark ? Color.clear : Color.orateCardBackground))
            .modifier(RecordCapsuleGlassStyle(colorScheme: colorScheme))
            
            Spacer()
            
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
    }
    
    private var stepCardView: some View {
        let currentStep = tutorialSteps[currentStepIndex]
        
        return VStack(spacing: 14) {
            HStack {
                Text(currentStep.stepText).font(.caption).foregroundColor(.orateSecondaryText)
                Spacer()
                Button("Skip tutorial") { withAnimation { isRecordingPage = true } }
                    .font(.caption).foregroundColor(.orateSecondaryText)
            }
            
            Image(systemName: currentStep.iconName)
                .font(.system(size: 26)).foregroundColor(.oratePrimaryText)
            Text(currentStep.title).font(.headline).fontWeight(.bold).foregroundColor(.oratePrimaryText)
            Text(currentStep.description)
                .font(.footnote).multilineTextAlignment(.center).foregroundColor(.orateSecondaryText)
            
            HStack(spacing: 6) {
                ForEach(0..<tutorialSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStepIndex ? Color.oratePrimaryText : Color.orateSecondaryText.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            Button(action: {
                withAnimation {
                    if currentStepIndex < tutorialSteps.count - 1 {
                        currentStepIndex += 1
                    } else {
                        isRecordingPage = true
                    }
                }
            }) {
                Text("Next")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.oratePrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.clear : Color.orateCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.clear : Color.orateCardBackground)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        )
        .modifier(RecordInstructionGlassStyle(colorScheme: colorScheme))
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
    private var recordingControlView: some View {
        VStack(spacing: 16) {
            Button(action: {
                if cameraManager.isRecording {
                    // Hand the recording to the analyzer first, then move to
                    // Loading straight away: the upload runs behind it.
                    router.latestAnalysis = nil
                    analysis.awaitRecording(from: cameraManager)
                    cameraManager.toggleRecording()
                    router.currentScreen = .loading
                } else {
                    cameraManager.toggleRecording()
                }
            }) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.6), lineWidth: 4).frame(width: 72, height: 72)
                    if cameraManager.isRecording {
                        RoundedRectangle(cornerRadius: 6).fill(Color.red).frame(width: 26, height: 26)
                    } else {
                        Circle().fill(Color.red).frame(width: 56, height: 56)
                    }
                }
            }
            
            Text(cameraManager.isRecording ? "Tap to Finish & Analyze Speech" : "Tap to Start Presentation")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
        .padding(.bottom, 20)
    }
}

private struct RecordCircleGlassStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 18, interactive: true)
        } else {
            content
        }
    }
}

private struct RecordCapsuleGlassStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 14)
        } else {
            content
        }
    }
}

private struct RecordInstructionGlassStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 24)
        } else {
            content
        }
    }
}

#Preview {
    CameraTutorialView()
        .environmentObject(AppRouter())
        .environmentObject(SpeechAnalysisViewModel())
}
