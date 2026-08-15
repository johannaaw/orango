//
//  GradeItemView.swift
//  OranGo
//
//  Individual grade breakdown card (e.g. "Grade A — 100.6 kg — 27.8%").
//

import SwiftUI

/// Displays a single grade's icon, name, weight, and percentage.
struct GradeItemView: View {
    let result: GradeResult

    var body: some View {
        VStack(spacing: 6) {
            // Grade icon placeholder
            // TODO: Replace SF Symbols with custom asset images matching the Figma design.
            ZStack {
                Circle()
                    .fill(result.gradeType.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: result.gradeType.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(result.gradeType.color)
            }

            // Grade name
            Text(result.gradeType.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.orangoTextPrimary)

            // Weight
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", result.weightKg).replacingOccurrences(of: ".", with: ","))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                Text("kg")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.orangoTextSecondary)
            }

            // Percentage
            Text(String(format: "%.1f%%", result.percentage).replacingOccurrences(of: ".", with: ","))
                .font(.system(size: 11))
                .foregroundStyle(Color.orangoTextSecondary)
        }
        .frame(minWidth: 64)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(GradeResult.sampleResults) { result in
            GradeItemView(result: result)
        }
    }
    .padding()
}
