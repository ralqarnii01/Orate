//
//  Onboarding3.swift
//  Orate
//
//  Created by Renad Alqarni on 29/02/1448 AH.
//

import SwiftUI

struct Onboarding3: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            // 1. لون الخلفية الأساسي
            Color.orateBackground
                .ignoresSafeArea()
            
            // 2. طبقة الأشكال الخلفية
            ZStack {
                Image("orate")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2.5)
                    .offset(x: -100, y: 440)
                
                Image("Flower")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2)
                    .offset(x: -130, y: -380)

                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(270))
                    .scaleEffect(1.5)
                    .offset(x: 170, y: -400)
            }
            .ignoresSafeArea()
            
            // 3. طبقة المحتوى الرئيسي (الشخصية والنصوص)
            VStack(spacing: 4) {
                Image("21")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2.3)
                
                // النصوص والنقاط
                VStack(spacing: 24) {
                    Text("Build your speaking\nhabit")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.oratePrimaryText)
                        .lineSpacing(4)
                    
                    Text("Follow a 30-day path of small speaking challenges to build confidence and consistency.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.orateSecondaryText)
                        
                    ZStack(alignment: .leading) {
                        // النقاط الرمادية الثابتة
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                            }
                        }
                        // النقطة الغامقة اللي تنزلق فوقهم
                        Circle()
                            .fill(Color.orateActiveText)
                            .frame(width: 9, height: 9)
                            .offset(x: CGFloat(selectedTab) * 16 - 0.5)
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
                        withAnimation { selectedTab = 3 }
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
    Onboarding3(selectedTab: .constant(2))
        .environmentObject(AppRouter())
}
