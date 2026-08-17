//
//  GradePatternFill.swift
//  OranGo
//
//  Reusable base fill + tiled pattern used by the donut chart and grade badges.
//

import SwiftUI

struct GradePatternFill: View {
    let appearance: GradeAppearance
    let patternAssetName: String?
    let patternScale: CGFloat

    var body: some View {
        appearance.fill
            .overlay {
                if let patternAssetName {
                    patternImage(patternAssetName)
                }
            }
            .clipped()
    }

    @ViewBuilder
    private func patternImage(_ name: String) -> some View {
        if let patternColor = appearance.patternColor {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .frame(width: patternScale, height: patternScale)
                .foregroundStyle(patternColor)
        } else {
            Image(name)
                .resizable()
                .interpolation(.high)
                .frame(width: patternScale, height: patternScale)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(GradeType.allCases, id: \.self) { grade in
            GradePatternFill(
                appearance: grade.badgeAppearance,
                patternAssetName: grade.patternAssetName,
                patternScale: 340
            )
            .frame(width: 52, height: 52)
            .clipShape(.circle)
        }
    }
    .padding()
}
