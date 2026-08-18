//
//  SummaryCardsView.swift
//  OranGo
//
//  Summary cards: Total Berat, Total Jumlah, Total Batch, Standar Grading.
//

import SwiftUI

struct SummaryCardsView: View {
    let weightKg: Double

    let count: Int

    let gradeLabel: String

    let gradingStandard: String

    var totalBatch: Int? = nil

    var placeholder: String? = nil

    var onGradingStandardInfo: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SummaryCardItem(
                title: "Total Berat",
                subtitle: gradeLabel,
                value: weightKg.formattedWeight,
                unit: "kg",
                placeholder: placeholder
            )

            SummaryCardItem(
                title: "Total Jumlah",
                subtitle: gradeLabel,
                value: count.formattedCount,
                unit: "buah",
                placeholder: placeholder
            )

            if let totalBatch {
                SummaryCardItem(
                    title: "Total Batch",
                    subtitle: "Semua batch periode ini",
                    value: "\(totalBatch)",
                    unit: "batch"
                )
            }

            SummaryCardItem(
                title: "Standar Grading",
                subtitle: "Standar grading yang digunakan",
                value: gradingStandard,
                unit: nil,
                placeholder: placeholder,
                isTextValue: true,
                onInfoTapped: onGradingStandardInfo
            )
            .frame(minWidth: 240)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Single Summary Card

private struct SummaryCardItem: View {
    let title: String
    let subtitle: String
    let value: String
    let unit: String?
    var placeholder: String? = nil
    var isTextValue: Bool = false
    var onInfoTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.orangoTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            valueRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(Color.orangoCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orangoBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var valueRow: some View {
        if let placeholder {
            Text(placeholder)
                .font(.caption)
                .foregroundStyle(Color.orangoTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else if isTextValue {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orangoTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                if let onInfoTapped {
                    Button(action: onInfoTapped) {
                        Image(systemName: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(Color.orangoTextTertiary)
                            .frame(width: 24, height: 24)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tentang standar grading")
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.orangoTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())

                if let unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(Color.orangoTextSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SummaryCardsView(
            weightKg: DashboardSummary.sample.totalWeightKg,
            count: DashboardSummary.sample.totalCount,
            gradeLabel: "Semua Grade",
            gradingStandard: DashboardSummary.sample.gradingStandard,
            totalBatch: DashboardSummary.sample.totalBatch
        )

        SummaryCardsView(
            weightKg: 96.4,
            count: 245,
            gradeLabel: "Grade B",
            gradingStandard: DashboardSummary.sample.gradingStandard
        )
    }
    .padding()
    .background(Color.orangoPageBackground)
}
