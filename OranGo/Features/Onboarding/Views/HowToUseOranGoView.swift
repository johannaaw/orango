//
//  HowToUseOranGoView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

//  Frame 3. Static 5-step walkthrough that appears right before the
//  device-connection flow begins.
//

import SwiftUI

struct HowToUseStep: Identifiable {
    let id: Int
    let imageName: String
    let title: String
}

struct HowToUseOranGoView: View {
    let onConnect: () -> Void

    private let steps: [HowToUseStep] = [
        .init(id: 1, imageName: "how-to-use-1", title: "Hubungkan App dengan alat OranGo"),
        .init(id: 2, imageName: "how-to-use-2", title: "Nyalakan alat OranGo"),
        .init(id: 3, imageName: "how-to-use-3", title: "Mulai sortir buah"),
        .init(id: 4, imageName: "how-to-use-4", title: "Dapatkan hasil grading buah"),
        .init(id: 5, imageName: "how-to-use-5", title: "Lihat laporan hasil sorting"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("How to use OranGo")
                .font(.system(size: 28, weight: .bold))

            VStack(alignment: .leading, spacing: 24) {
                ForEach(steps) { step in
                    HowToUseRow(step: step)
                }
            }

            OnboardingButton(title: "Hubungkan OranGo", isEnabled: true, action: onConnect)
                .padding(.top, 8)
        }
        .padding(44)
        
    }
}

private struct HowToUseRow: View {
    let step: HowToUseStep

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.oranGoOrange)
                    .frame(width: 30, height: 30)
                Text("\(step.id)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            Image(step.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(step.title)
                .font(.system(size: 18, weight: .semibold))

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    
    ZStack {
        OnboardingPopupBackdrop()
        OnboardingPopupCard {
            HowToUseOranGoView(onConnect: {})
        }
        .padding(.horizontal, 100)
    }
}
