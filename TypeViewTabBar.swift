//
//  TypeViewTabBar.swift
//  Orate
//
//  Created by Niroz on 22/02/1448 AH.
//

import SwiftUI

struct TypeViewTabBar: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    var activeTab: Int // 0: progress, 1: practice, 2: orate way
    
    private let activeColor = Color.oratePrimaryText
    private let inactiveColor = Color.orateSecondaryText
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.clear)
                    .frame(width: 341, height: 73)
                    .frostGlass(cornerRadius: 30)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.orateCardBackground)
                    .frame(width: 341, height: 73)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .allowsHitTesting(false)
            }
            
            HStack(spacing: 0) {
                // progress tab button
                tabButton(
                    title: "Progress",
                    isActive: activeTab == 0,
                    action: { router.currentScreen = .progress }
                ) {
                    Image("brain_cloud_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.22)
                }
                
                // practice tab button
                tabButton(
                    title: "Practice",
                    isActive: activeTab == 1,
                    action: { router.currentScreen = .practice }
                ) {
                    Image(systemName: "mic")
                        .font(.system(size: 24, weight: .regular))
                        .frame(width: 32, height: 32)
                }
                
                // orate way tab button
                tabButton(
                    title: "Orate Way",
                    isActive: activeTab == 2,
                    action: { router.currentScreen = .orateWay }
                ) {
                    Image(systemName: "map")
                        .font(.system(size: 23, weight: .regular))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 14)
            .zIndex(1)
        }
        .frame(width: 341, height: 73)
    }
    
    private func tabButton<Icon: View>(
        title: String,
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                icon()
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? activeColor : inactiveColor)
        .opacity(isActive ? 1.0 : (colorScheme == .dark ? 0.68 : 0.4))
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
    }
}
