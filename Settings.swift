import AVFoundation
import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isNameFocused: Bool
    
    @State private var isCameraEnabled = true
    @State private var isMicrophoneEnabled = true
    
    @AppStorage("appearanceMode") private var appearanceMode = 0
    @AppStorage("userName") private var userName = ""
    @AppStorage("profileImage") private var profileImage = ""
    
    @State private var showingImagePicker = false
    
    private let availableImages = ["cloud2", "flower2", "mas2", "orate2"]
    private let activeColor = Color.orateActiveText
    private let editColor = Color(hex: "#5E64AC")

    private var isDarkModeActive: Binding<Bool> {
        Binding(
            get: {
                if appearanceMode == 0 {
                    return colorScheme == .dark
                }

                return appearanceMode == 2
            },
            set: { isOn in
                appearanceMode = isOn ? 2 : 1
            }
        )
    }
    
    var body: some View {
        ZStack {
            Color.orateBackground
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                Circle()
                    .fill(Color(red: 167/255, green: 228/255, blue: 218/255).opacity(0.8))
                    .frame(width: 260, height: 260)
                    .position(x: geometry.size.width + 30, y: 150)
                
                Circle()
                    .fill(Color(red: 167/255, green: 228/255, blue: 218/255).opacity(0.8))
                    .frame(width: 340, height: 340)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 30)
                    .padding(.top, 18)
                
                accountCard
                    .padding(.horizontal, 30)
                    .padding(.top, 28)
                
                settingsTitle
                    .padding(.leading, 45)
                    .padding(.top, 24)
                    .padding(.bottom, 5)
                
                settingsList
                    .frame(width: 341)
                
                Spacer()
            }
        }
        .onTapGesture {
            isNameFocused = false
        }
        .sheet(isPresented: $showingImagePicker) {
            profileImagePicker
                .presentationDetents([.height(200)])
                .preferredColorScheme(preferredColorScheme)
        }
        .onAppear {
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkPermissions()
        }
    }
    
    private var headerSection: some View {
        ZStack {
            HStack {
                Button {
                    router.currentScreen = .progress
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(activeColor)
                        .frame(width: 46, height: 46)
                        .background(
                            Group {
                                if colorScheme == .dark {
                                    Circle().fill(.clear)
                                } else {
                                    Circle().fill(Color.orateCardBackground)
                                }
                            }
                        )
                        .clipShape(Circle())
                }
                .modifier(CircleButtonBackgroundStyle(colorScheme: colorScheme))
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            Text("Account")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.oratePrimaryText)
        }
    }
    
    private var accountCard: some View {
        HStack(spacing: 15) {
            Button {
                showingImagePicker = true
            } label: {
                profileImageView(size: 75)
            }
            .buttonStyle(.plain)
            .padding(.leading, 15)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Enter your name", text: $userName)
                        .focused($isNameFocused)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.oratePrimaryText)
                        .tint(editColor)
                    
                    Rectangle()
                        .fill(isNameFocused ? editColor.opacity(0.55) : Color.clear)
                        .frame(height: 1)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isNameFocused = true
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isNameFocused ? editColor : activeColor.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 15)
            
            Spacer()
        }
        .frame(height: 100)
        .modifier(SettingsCardStyle(colorScheme: colorScheme))
    }
    
    private var settingsTitle: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(activeColor)
            
            Spacer()
        }
    }
    
    private var settingsList: some View {
        VStack(spacing: 0) {
            Toggle(isOn: isDarkModeActive) {
                Text("Dark Mode")
                    .font(.system(size: 16))
                    .foregroundColor(.oratePrimaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .tint(Color(hex: "#7478C8"))
            
            Divider().padding(.horizontal, 16)
            
            Toggle(isOn: Binding(
                get: { isCameraEnabled },
                set: { _ in openAppSettings() }
            )) {
                Text("Camera")
                    .font(.system(size: 16))
                    .foregroundColor(.oratePrimaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .tint(Color(hex: "#7478C8"))
            
            Divider().padding(.horizontal, 16)
            
            Toggle(isOn: Binding(
                get: { isMicrophoneEnabled },
                set: { _ in openAppSettings() }
            )) {
                Text("Microphone")
                    .font(.system(size: 16))
                    .foregroundColor(.oratePrimaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .tint(Color(hex: "#7478C8"))
            
            Divider().padding(.horizontal, 16)
            
            Button {
                openSupportEmail()
            } label: {
                HStack {
                    Text("Help & Support")
                        .font(.system(size: 16))
                        .foregroundColor(.oratePrimaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(activeColor)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .modifier(SettingsCardStyle(colorScheme: colorScheme))
    }
    
    private var profileImagePicker: some View {
        VStack(spacing: 20) {
            Text("Choose Profile Picture")
                .font(.headline)
                .padding(.top, 20)
            
            HStack(spacing: 16) {
                ForEach(availableImages, id: \.self) { imageName in
                    Button {
                        profileImage = imageName
                        showingImagePicker = false
                    } label: {
                        ZStack {
                            Circle()
                                .fill(getBackgroundColor(for: imageName))
                                .frame(width: 65, height: 65)
                            
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 45, height: 45)
                                .scaleEffect(imageName == "mas2" ? 1.2 : 1.8)
                                .offset(y: imageName == "orate2" ? 8 : 0)
                        }
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: profileImage == imageName ? 3 : 0)
                        )
                        .scaleEffect(profileImage == imageName ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
    }
    
    private func profileImageView(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(getBackgroundColor(for: profileImage))
                .frame(width: size, height: size)
                .overlay(
                    Group {
                        switch profileImage {
                        case "orate2":
                            Image(profileImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(2.5)
                                .offset(x: 1, y: 13)
                        case "cloud2":
                            Image(profileImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(2)
                                .offset(x: 0, y: -2)
                        case "flower2":
                            Image(profileImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(2.2)
                                .offset(x: 2, y: -1)
                        case "mas2":
                            Image(profileImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(2)
                                .offset(x: -2, y: 2)
                        default:
                            Image(profileImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55)
                        }
                    }
                )
            
            ZStack {
                Circle()
                    .fill(Color.orateCardBackground)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.oratePrimaryText)
            }
            .offset(x: 5, y: 5)
        }
    }
    
    private func getBackgroundColor(for imageName: String) -> Color {
        switch imageName {
        case "cloud2":
            return colorScheme == .dark ? Color(hex: "#604141") : Color(hex: "#FAAFAF")
        case "flower2":
            return colorScheme == .dark ? Color(hex: "#383B61") : Color(hex: "#9A9ECD")
        case "mas2":
            return colorScheme == .dark ? Color(hex: "#415E5D") : Color(hex: "#BFEFEF")
        case "orate2":
            return colorScheme == .dark ? Color(hex: "#665E3A") : Color(hex: "#FFF1B4")
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    private func openSupportEmail() {
        let email = "oratesupport@gmail.com"
        let subject = "Support Request".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let gmailString = "googlegmail:///co?to=\(email)&subject=\(subject)"
        let mailtoString = "mailto:\(email)?subject=\(subject)"
        
        if let gmailURL = URL(string: gmailString),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL)
        } else if let mailtoURL = URL(string: mailtoString),
                  UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL)
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil
        }
    }

    private func checkPermissions() {
        isCameraEnabled = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        isMicrophoneEnabled = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}

private struct SettingsCardStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .frostGlass(cornerRadius: 26)
        } else {
            content
                .background(Color.orateMenuBackground)
                .cornerRadius(26)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        }
    }
}

private struct CircleButtonBackgroundStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .frostGlass(cornerRadius: 23, interactive: true)
        } else {
            content
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AppRouter())
}
