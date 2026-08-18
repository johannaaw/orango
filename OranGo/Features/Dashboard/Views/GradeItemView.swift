//
//  GradeItemView.swift
//  OranGo
//
//  Individual grade breakdown column (e.g. "Grade A — 100,6 kg — 27,8%").
//

import SwiftUI

struct GradeItemView: View {
    let result: GradeResult

    var isSelected: Bool = false

    var isDimmed: Bool = false

    var onTap: (() -> Void)? = nil

    private let badgeSize: CGFloat = 52

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 8) {
                badge
                    .grayscale(isDimmed ? 1 : 0)

                Text(result.gradeType.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.orangoTextPrimary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(result.isEmpty ? "0" : result.weightKg.formattedWeight)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.orangoTextPrimary)

                    Text("kg")
                        .font(.caption2)
                        .foregroundStyle(Color.orangoTextSecondary)
                }

                Text(result.isEmpty ? "0%" : result.percentage.formattedWeight + "%")
                    .font(.caption2)
                    .foregroundStyle(Color.orangoTextSecondary)
            }
            .opacity(isDimmed ? 0.65 : 1)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(selectionBackground)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(result.gradeType.displayName)
        .accessibilityValue("\(result.weightKg.formattedWeight) kilogram, \(result.count.formattedCount) buah, \(result.percentage.formattedWeight) persen")
        .accessibilityHint(isSelected ? "Ketuk untuk kembali ke semua grade" : "Ketuk untuk melihat ringkasan grade ini")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Selection

    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 12)
                .fill(result.gradeType.selectionTint)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orangoBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Badge

    private var badge: some View {
        let appearance = result.gradeType.badgeAppearance

        return GradePatternFill(
            appearance: appearance,
            patternAssetName: result.gradeType.patternAssetName,
            patternScale: badgeSize * 6.5
        )
        .frame(width: badgeSize, height: badgeSize)
        .clipShape(.circle)
        .overlay {
            if let border = appearance.border {
                Circle().strokeBorder(border, lineWidth: 1.5)
            }
        }
        .overlay {
            glyph(ink: appearance.ink)
        }
    }

    @ViewBuilder
    private func glyph(ink: Color) -> some View {
        let appearance = result.gradeType.badgeAppearance

        if result.gradeType.isSymbol {
            let symbolSize = badgeSize * 0.36
            let halo: CGFloat = appearance.inkOutline == nil ? 2 : 0

            OutlinedSymbol(
                systemName: result.gradeType.chartLabel,
                size: symbolSize,
                fill: ink,
                outline: appearance.inkOutline,
                outlineWidth: symbolSize * 0.09
            )
            .shadow(color: appearance.fill, radius: halo)
            .shadow(color: appearance.fill, radius: halo)
        } else {
            let glyphSize = badgeSize * 0.46
            let halo: CGFloat = appearance.inkOutline == nil ? 2 : 0

            OutlinedGlyph(
                string: result.gradeType.chartLabel,
                size: glyphSize,
                weight: .black,
                fill: ink,
                outline: appearance.inkOutline,
                outlineWidth: glyphSize * 0.06
            )
            .shadow(color: appearance.fill, radius: halo)
            .shadow(color: appearance.fill, radius: halo)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 0) {
        ForEach(GradeResult.sampleResults) { result in
            GradeItemView(
                result: result,
                isSelected: result.gradeType == .gradeB,
                isDimmed: result.gradeType != .gradeB
            )
        }
    }
    .padding()
    .background(Color.orangoCardBackground)
}
