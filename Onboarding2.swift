//
//  Onboarding2.swift
//  Orate
//
//  Created by Niroz on 21/02/1448 AH.
//

import SwiftUI

struct Onboarding2: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            // 1. لون الخلفية الأساسي
            Color.orateBackground
                .ignoresSafeArea()
            
            ZStack {
                Image("orate")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2.5) // عدّل الحجم هنا
                    .offset(x: -100, y: 440) // عدّل الموقع (x: يمين/يسار , y: فوق/تحت)
                
                Image("Flower")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2)
                    .offset(x: -130, y: -380)
                
                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(270))
                    .scaleEffect(1.5)// عدّل الحجم هنا
                    .offset(x: 170, y: -400) // عدّل الموقع
            }
            .ignoresSafeArea()
            
            // 3. طبقة المحتوى الرئيسي (الشخصية والنصوص)
            VStack(spacing:4) {
                
                Image("9")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2.5) // تحكم بحجم الشخصية بسهولة من هنا
                
                // النصوص والنقاط
                VStack(spacing: 24) {
                    Text("Real-time feedback on how you speak and move")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.oratePrimaryText)
                        .lineSpacing(4)
                    
                    Text("Friendly AI guidance in every session")
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
                        withAnimation { selectedTab = 2 }
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
    Onboarding2(selectedTab: .constant(1))
        .environmentObject(AppRouter())
}
