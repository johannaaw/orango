//
//  OnboardingPopupCard.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

import SwiftUI

struct OnboardingPopupCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: 700, maxHeight: 650)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.18), radius: 40, x: 0, y: 16)
            )
    }
}

/// background di belakang PopupCard
struct OnboardingPopupBackdrop: View {
    var body: some View {
        Color.black.opacity(0.25)
            .ignoresSafeArea()
    }
}
