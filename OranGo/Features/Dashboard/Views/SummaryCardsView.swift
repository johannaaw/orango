//
//  SummaryCardsView.swift
//  OranGo
//
//  Three summary cards: Total Berat, Total Jumlah, Standar Grading.
//

import SwiftUI

/// Horizontal row of three summary metric cards.
struct SummaryCardsView: View {
    let summary: DashboardSummary

    var body: some View {
        HStack(spacing: 12) {
            // Total Berat
            SummaryCardItem(
                title: "Total Berat",
                subtitle: "Semua Grade",
                value: String(format: "%.1f", summary.totalWeightKg)
                    .replacingOccurrences(of: ".", with: ","),
                unit: "kg",
                accentColor: .orangoBrandOrange
            )

            // Total Jumlah
            SummaryCardItem(
                title: "Total Jumlah",
                subtitle: "Semua Grade",
                value: formatNumber(summary.totalCount),
                unit: "buah",
                accentColor: .orangoBrandOrange
            )

            // Standar Grading
            SummaryCardItem(
                title: "Standar Grading",
                subtitle: "Standar grading yang digunakan",
                value: summary.gradingStandard,
                unit: nil,
                accentColor: .orangoBrandOrange,
                isTextValue: true
            )
        }
    }

    /// Formats an integer with dot separators (e.g., 1245 → "1.245").
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Single Summary Card

/// A single summary metric card.
private struct SummaryCardItem: View {
    let title: String
    let subtitle: String
    let value: String
    let unit: String?
    let accentColor: Color
    var isTextValue: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.orangoTextSecondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Value + unit
            if isTextValue {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.orangoTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.orangoTextPrimary)

                    if let unit {
                        Text(unit)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.orangoTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangoCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orangoBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    SummaryCardsView(summary: .sample)
        .padding()
        .background(Color.orangoPageBackground)
}
