//
//  Onboarding1.swift
//  Orate
//
//  Created by Niroz on 21/02/1448 AH.
//

import SwiftUI

struct Onboarding1: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            // 1. لون الخلفية الأساسي
            Color.orateBackground
                .ignoresSafeArea()
            
            // 2. طبقة الأشكال الخلفية (تحكم مباشر بالـ offset و frame)
            ZStack {
                // الشكل التيركواز (أسفل يسار)
                Image("mas")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(3.5) // عدّل الحجم هنا
                    .offset(x: -100, y: 540) // عدّل الموقع (x: يمين/يسار , y: فوق/تحت)
                
                // الشكل البنفسجي الزهري (يمين تحت النص)
                Image("Flower")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(1.3)
                    .offset(x: 190, y: 250) // عدّل الموقع
                
                // السحابة الوردية (أقصى الأسفل يمين)
                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(1.5)// عدّل الحجم هنا
                    .offset(x: 130, y: 390) // عدّل الموقع
            }
            .ignoresSafeArea()
            
            // 3. طبقة المحتوى الرئيسي (الشخصية والنصوص)
            VStack(spacing:4) {
                
                // الشخصية الصفراء في المنتصف
                Image("12")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2.5) // تحكم بحجم الشخصية بسهولة من هنا
                
                // النصوص والنقاط
                VStack(spacing: 24) {
                    Text("Build your speaking\nconfidence step by step")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.oratePrimaryText)
                        .lineSpacing(4)
                    
                    Text("Big progress starts with small daily habits")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.orateSecondaryText)
                        
                    ZStack(alignment: .leading) {
                        // 1. النقاط الرمادية الثابتة
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                            }
                        }
                        // 2. النقطة الغامقة اللي تنزلق فوقهم (روحه وجيه)
                        Circle()
                            .fill(Color.orateActiveText)
                            .frame(width: 9, height: 9)
                            .offset(x: CGFloat(selectedTab) * 16 - 0.5) // تحرك النقطة حسب الصفحة
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // زر "Next"
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation { selectedTab = 1 }
                    }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.oratePrimaryText)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.orateCardBackground)
                                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

#Preview {
    // التعديل صار هنا بإضافة selectedTab: .constant(0)
    Onboarding1(selectedTab: .constant(0))
        .environmentObject(AppRouter())
}



struct MainOnboardingView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Onboarding1(selectedTab: $selectedTab)
                .tag(0)
            
            Onboarding2(selectedTab: $selectedTab)
                .tag(1)

            Onboarding3(selectedTab: $selectedTab)
                .tag(2)

            OnboardingStep3View(selectedTab: $selectedTab)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) // يخليها تسحب زي الصفحات
        .animation(.easeInOut, value: selectedTab) // هذا السطر يضمن لك نعومة الانتقال لما تضغطين زر Next
        .ignoresSafeArea()
    }
}

// جربي السحب والضغط من هنا! 👇
#Preview {
    MainOnboardingView()
        .environmentObject(AppRouter())
}
