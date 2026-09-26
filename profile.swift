//
//  profile.swift
//  Orate
//
//  Created by shahad hamdi on 21/02/1448 AH.
//

import SwiftUI

enum AvatarType: String, CaseIterable, Identifiable {
    case bubble = "mas"
    case orate  = "orate"
    case cloud  = "cloud"
    case flower = "flower"
    
    var id: String { self.rawValue }
    
    var profileImageName: String {
        return "\(self.rawValue)2"
    }
    
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .bubble: return colorScheme == .dark ? Color(hex: "#415E5D") : Color(hex: "#BFEFEF")
        case .orate: return colorScheme == .dark ? Color(hex: "#665E3A") : Color(hex: "#FFF1B4")
        case .cloud: return colorScheme == .dark ? Color(hex: "#604141") : Color(hex: "#FAAFAF")
        case .flower: return colorScheme == .dark ? Color(hex: "#383B61") : Color(hex: "#9A9ECD")
        }
    }
}

struct OnboardingStep3View: View {
    enum Field: Hashable {
        case name
        case age
    }
    
    @Binding var selectedTab: Int
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var focusedField: Field?
    
    @State private var selectedAvatar: AvatarType? = nil
    @State private var isPickerVisible: Bool = false
    
    @State private var nameText: String = ""
    @State private var ageText: String = ""
    
    @AppStorage("userName") private var savedUserName = ""
    @AppStorage("profileImage") private var savedProfileImage = ""
    @AppStorage("isGuestUser") private var isGuestUser = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var showAgeError: Bool = false
    @State private var showNameError: Bool = false
    @State private var showAvatarError: Bool = false
    
    var onFinish: () -> Void = {}
    
    private let backgroundColor = Color.orateBackground
    private let activeColor = Color.orateActiveText
    private let inactiveColor = Color.orateSecondaryText
    
    private func continueAsGuest() {
        savedUserName = "Guest"
        savedProfileImage = AvatarType.orate.profileImageName
        isGuestUser = true
        hasCompletedOnboarding = true
        onFinish()
        router.currentScreen = .progress
        }
        
        var body: some View {
            ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                Image("orate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
                    .scaleEffect(2.3)
                    .offset(x: proxy.size.width - 110, y: proxy.size.height * 0.18)
                
                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(90))
                    .frame(width: 240)
                    .scaleEffect(3.0)
                    .offset(x: -100, y: proxy.size.height * 0.65)
            }
            .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        if isPickerVisible {
                            HStack(spacing: 16) {
                                ForEach(AvatarType.allCases) { avatar in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            selectedAvatar = avatar
                                            showAvatarError = false
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(avatar.backgroundColor(for: colorScheme))
                                                .frame(width: 56, height: 56)
                                            
                                            Image(avatar.profileImageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .scaleEffect(avatar == .bubble ? 1.2 : 1.8)
                                                .offset(y: avatar == .orate ? 8 : 0)
                                        }
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedAvatar == avatar ? 3 : 0)
                                        )
                                        .scaleEffect(selectedAvatar == avatar ? 1.15 : 1.0)
                                        .shadow(color: selectedAvatar == avatar ? Color.black.opacity(0.12) : Color.clear, radius: 5)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.orateCardBackground.opacity(0.85))
                            .clipShape(Capsule())
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 20)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("Express yourself with an avatar")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(inactiveColor)
                                
                                if showAvatarError {
                                    Text("*")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.red)
                                }
                            }
                            
                            ZStack(alignment: .bottomTrailing) {
                                ZStack {
                                    Circle()
                                        .fill(selectedAvatar?.backgroundColor(for: colorScheme) ?? (colorScheme == .dark ? Color.orateCardBackground.opacity(0.3) : Color(white: 0.88)))
                                        .frame(width: 220, height: 220)
                                    
                                    if let avatar = selectedAvatar {
                                        Image(avatar.profileImageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 175, height: 175)
                                            .scaleEffect(avatar == .bubble ? 2.1 : 2.5)
                                            .offset(y: avatar == .orate ? 25 : 0)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 90, height: 90)
                                            .foregroundColor(Color.gray.opacity(0.5))
                                    }
                                }
                                .padding(10)
                                .background(Color.orateCardBackground)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                                .overlay(
                                    Circle()
                                        .stroke(showAvatarError ? Color.red : Color.clear, lineWidth: 2)
                                )
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isPickerVisible.toggle()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orateCardBackground)
                                            .frame(width: 48, height: 48)
                                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                                        
                                        Image(systemName: isPickerVisible ? "checkmark" : "plus")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(activeColor)
                                    }
                                }
                                .offset(x: 2, y: 2)
                            }
                        }
                        
                        Spacer(minLength: 20)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Name Section
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("Name")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(activeColor)
                                    
                                    if showNameError {
                                        Text("* required")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                TextField("Enter your name", text: $nameText)
                                    .font(.system(size: 15))
                                    .foregroundColor(.oratePrimaryText)
                                    .padding(.vertical, 4)
                                    .focused($focusedField, equals: .name)
                                    .id(Field.name)
                                    .onChange(of: nameText) { _, _ in showNameError = false }
                                
                                Divider()
                                    .background(showNameError ? Color.red : activeColor.opacity(0.6))
                            }
                            
                            // Age Section
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("Age")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(activeColor)
                                    
                                    if showAgeError {
                                        Text("* Must be 15 or older")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                TextField("Enter your age", text: $ageText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 15))
                                    .foregroundColor(.oratePrimaryText)
                                    .padding(.vertical, 4)
                                    .focused($focusedField, equals: .age)
                                    .id(Field.age)
                                    .onChange(of: ageText) { _, _ in showAgeError = false }
                                
                                Divider()
                                    .background(showAgeError ? Color.red : activeColor.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        ZStack(alignment: .leading) {
                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                                }
                            }
                            Circle()
                                                           .fill(activeColor)
                                                           .frame(width: 9, height: 9)
                                                           .offset(x: CGFloat(3) * 16 - 0.5)
                                                           .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                                                   }
                                                   .padding(.top, 10)
                    
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                let age = Int(ageText) ?? 0
                                let isAgeValid = age >= 15
                                let isNameValid = !nameText.trimmingCharacters(in: .whitespaces).isEmpty
                                let isAvatarValid = selectedAvatar != nil
                                
                                withAnimation {
                                    showAgeError = !isAgeValid
                                    showNameError = !isNameValid
                                    showAvatarError = !isAvatarValid
                                }
                                
                                if isAgeValid && isNameValid && isAvatarValid {
                                    savedUserName = nameText
                                    savedProfileImage = selectedAvatar?.profileImageName ?? ""
                                    isGuestUser = false
                                    hasCompletedOnboarding = true
                                    
                                    onFinish()
                                    router.currentScreen = .progress
                                }
                            }) {
                                Text("Let's Start !")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(activeColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.orateCardBackground)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: continueAsGuest) {
                                Text("Try without signing up")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(activeColor.opacity(0.8))
                                    .underline()
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    // إضافة مساحة ديناميكية في أسفل المحتوى عند فتح الكيبورد
                    .padding(.bottom, focusedField != nil ? 280 : 20)
                    .animation(.easeInOut(duration: 0.25), value: focusedField)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, field in
                    if let field = field {
                        // إعطاء مهلة بسيطة جداً ليتحرك الكيبورد ثم رفعه لأعلى نقطة
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(field, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }
}

#Preview {
    OnboardingStep3View(selectedTab: .constant(3))
        .environmentObject(AppRouter())
}
