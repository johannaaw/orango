//
//  InsightsPanenView.swift
//  OranGo
//
//  Harvest insights section with numbered ranked items.
//

import SwiftUI

struct InsightsPanenView: View {
    let insights: [HarvestInsight]

    /// Explains why the on-device model was not used, when that is the case.
    var notice: String? = nil

    var isLoading: Bool = false

    /// The snapshot the insights were written from, so the card can show what its
    /// percentages were measured against.
    var basis: InsightSnapshot? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Insight panen")
                    .font(.headline)
                    .foregroundStyle(Color.orangoTextPrimary)

                if isLoading {
                    ProgressView().controlSize(.small)
                }
            }

            if insights.isEmpty {
                Text(isLoading ? "Menyusun insight…" : "Belum ada data untuk dianalisis.")
                    .font(.caption)
                    .foregroundStyle(Color.orangoTextSecondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(insights) { insight in
                        InsightItemRow(insight: insight)
                    }
                }
            }

            comparisonBasis

            if let notice {
                Text(notice)
                    .font(.caption2)
                    .foregroundStyle(Color.orangoTextTertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangoCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orangoBorder, lineWidth: 1)
        )
    }
}

// MARK: - Comparison Basis

private extension InsightsPanenView {

    /// Shows both sides of every percentage above, so a stated change can be checked rather
    /// than taken on trust.
    @ViewBuilder
    var comparisonBasis: some View {
        if let basis, let previous = basis.comparison, !insights.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Divider().overlay(Color.orangoBorder)

                Text("Dibandingkan dengan \(previous.label) — \(previous.periodLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.orangoTextSecondary)
                    .padding(.top, 2)

                BasisRow(
                    label: "Reject",
                    before: previous.rejectPercentage,
                    after: basis.rejectPercentage
                )

                BasisRow(
                    label: "Lolos retail",
                    before: previous.retailGradePercentage,
                    after: basis.retailGradePercentage
                )

                if previous.totalWeightKg > 0 {
                    BasisRow(
                        label: "Volume",
                        change: (basis.totalWeightKg - previous.totalWeightKg) / previous.totalWeightKg * 100
                    )
                }

                if let before = previous.throughputPerHour,
                   let now = basis.throughputPerHour,
                   before > 0 {
                    BasisRow(label: "Laju sortir", change: (now - before) / before * 100)
                }
            }
            .padding(.top, 4)
        }
    }
}

/// One line of the basis block: either a before → after pair, or a single relative change.
private struct BasisRow: View {
    let label: String
    var before: Double? = nil
    var after: Double? = nil
    var change: Double? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.orangoTextSecondary)
                .frame(width: 92, alignment: .leading)

            if let before, let after {
                Text("\(before.formattedWeight)%")
                    .foregroundStyle(Color.orangoTextSecondary)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(Color.orangoTextTertiary)

                Text("\(after.formattedWeight)%")
                    .foregroundStyle(Color.orangoTextPrimary)
            } else if let change {
                Text("\(change >= 0 ? "+" : "−")\(abs(change).formattedWeight)%")
                    .foregroundStyle(Color.orangoTextPrimary)
            }

            Spacer(minLength: 0)
        }
        .font(.caption.monospacedDigit())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Single Insight Row

private struct InsightItemRow: View {
    let insight: HarvestInsight

    var body: some View {
        HStack(spacing: 12) {
            Text("\(insight.rank)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.orangoDarkOrange))

            Text(insight.description)
                .font(.subheadline)
                .foregroundStyle(Color.orangoTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insight \(insight.rank): \(insight.description)")
    }
}

// MARK: - Preview

#Preview {
    InsightsPanenView(insights: HarvestInsight.sampleInsights)
        .padding()
        .background(Color.orangoPageBackground)
}
