//
//  OnboardingWelcomeView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//


//  Frame 1 (Onboarding-1). Full-screen splash: logo mark + "Welcome To OranGo".
//  No button in the mockup, so this auto-advances to Frame 2 after a short delay. Adjust `autoAdvanceDelay` or swap for a tap gesture if a manual trigger is preferred instead.

import SwiftUI

struct OnboardingWelcomeView: View {
    let onFinishedSplash: () -> Void

    private let autoAdvanceDelay: Duration = .seconds(1.6)

    var body: some View {
        VStack(spacing: 20) {
            Image("logo-orango")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            VStack(spacing: 2) {
                Text("Welcome To")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundStyle(.primary)
                Text("OranGo")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundStyle(Color.orangoBrandOrange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            try? await Task.sleep(for: autoAdvanceDelay)
            onFinishedSplash()
        }
    }
}

#Preview {
    OnboardingWelcomeView(onFinishedSplash: {})
}
