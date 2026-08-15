//
//  InsightsPanenView.swift
//  OranGo
//
//  Harvest insights section with numbered ranked items.
//

import SwiftUI

/// Section card displaying ranked harvest insights.
struct InsightsPanenView: View {
    let insights: [HarvestInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Insight panen")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            // Insight items
            VStack(alignment: .leading, spacing: 10) {
                ForEach(insights) { insight in
                    InsightItemRow(insight: insight)
                }
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

// MARK: - Single Insight Row

/// A single numbered insight item.
private struct InsightItemRow: View {
    let insight: HarvestInsight

    /// Color for the rank badge based on rank number.
    private var rankColor: Color {
        switch insight.rank {
        case 1: return .insightRank1
        case 2: return .insightRank2
        case 3: return .insightRank3
        default: return .orangoTextSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(insight.rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(rankColor)
                )

            // Description text
            Text(insight.description)
                .font(.system(size: 14))
                .foregroundStyle(Color.orangoTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsPanenView(insights: HarvestInsight.sampleInsights)
        .padding()
        .background(Color.orangoPageBackground)
}
