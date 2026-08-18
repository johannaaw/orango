//
//  OnboardingButton.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//


//  Reusable pill-shaped CTA used throughout onboarding.
//  Matches the two states seen in the mockup: enabled (solid orange) and
//  disabled (light gray, muted text).
//

import SwiftUI

struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isEnabled ? .white : Color(.tertiaryLabel))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(isEnabled ? Color.orangoBrandOrange : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingButton(title: "Mulai memantau sorting", isEnabled: true) {}
        OnboardingButton(title: "Mulai memantau sorting", isEnabled: false) {}
    }
    .padding(40)
}
