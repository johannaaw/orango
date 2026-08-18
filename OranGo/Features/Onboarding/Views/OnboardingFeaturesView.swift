//
//  OnboardingFeaturesView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

//  Frame 2 (Onboarding-2). Full-screen: title + 4 feature bullets + "Mulai".
//
//  NOTE: the 4 feature icons were solid black placeholder boxes in the
//  mockup (no final asset provided yet). Using SF Symbols here as a
//  stand-in — swap `OnboardingFeature.icon` values or the icon rendering
//  in `FeatureRow` once real assets/icons are decided.
//

import SwiftUI

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String   // SF Symbol name (placeholder — see note above)
    let title: String
    let description: String
}

struct OnboardingFeaturesView: View {
    let onStart: () -> Void

    private let features: [OnboardingFeature] = [
        .init(
            icon: "🟠",
            title: "Grading Otomatis",
            description: "OranGo membantu menilai jeruk berdasarkan berat, ukuran, dan warna secara otomatis."
        ),
        .init(
            icon: "⏳",
            title: "Hasil Seketika",
            description: "Lihat hasil grading setiap jeruk segera setelah proses selesai."
        ),
        .init(
            icon: "📊",
            title: "Ringkasan Grading",
            description: "Pantau jumlah jeruk berdasarkan grade dalam satu dashboard."
        ),
        .init(
            icon: "📑",
            title: "Riwayat Data",
            description: "Simpan dan pantau hasil grading untuk melihat perkembangan proses sortir."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 2) {
                Text("Welcome To")
                    .font(.system(size: 60, weight: .heavy))
                Text("OranGo")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundStyle(Color.oranGoOrange)
            }
            .padding(.bottom, 30)

            VStack(alignment: .leading, spacing: 26) {
                ForEach(features) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.top, 48)

            Spacer(minLength: 40)

            OnboardingButton(title: "Mulai", isEnabled: true, action: onStart)
                .frame(maxWidth: 560)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct FeatureRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(feature.icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 17, weight: .semibold))
                Text(feature.description)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.oranGoSecondaryText)
            }
        }
    }
}

#Preview {
    OnboardingFeaturesView(onStart: {})
}
