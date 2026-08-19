//
//  OnboardingFeaturesView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

//  Frame 2 (Onboarding-2). Full-screen: title + 4 feature bullets + "Mulai",
//  with the mascot waving from the top-left and cheering from the bottom-right.
//

import SwiftUI

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
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
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            // Mascots sit behind nothing and overlap nothing — they are pinned to the two
            // corners the content column leaves empty.
            .overlay(alignment: .topLeading) { wavingMascot }
            .overlay(alignment: .bottomTrailing) { cheeringMascot }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            title

            VStack(alignment: .leading, spacing: 22) {
                ForEach(features) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .frame(maxWidth: 400, alignment: .leading)
            .padding(.top, 40)

            Spacer(minLength: 32)

            OnboardingButton(title: "Mulai", isEnabled: true, action: onStart)
                .frame(maxWidth: 640)
                .padding(.bottom, 44)
        }
        .padding(.horizontal, 40)
    }

    private var title: some View {
        VStack(spacing: 2) {
            Text("Welcome To")
                .font(.system(size: 60, weight: .heavy))
                .foregroundStyle(.primary)

            Text("OranGo")
                .font(.system(size: 60, weight: .heavy))
                .foregroundStyle(Color.orangoBrandOrange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome To OranGo")
    }

    // MARK: - Mascots

    private var wavingMascot: some View {
        Image("MASKOT DEFAULT 1")
            .resizable()
            .scaledToFit()
            .frame(width: 220)
            .padding(.leading, 90)
            .padding(.top, 100)
            .accessibilityHidden(true)
    }

    private var cheeringMascot: some View {
        Image("MASKOT FUN 1")
            .resizable()
            .scaledToFit()
            .frame(width: 220)
            .padding(.trailing, 100)
            .padding(.bottom, 150)
            .accessibilityHidden(true)
    }
}

private struct FeatureRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(feature.icon)
                .font(.system(size: 26))

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(feature.description)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.orangoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingFeaturesView(onStart: {})
}
