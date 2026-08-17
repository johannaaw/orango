//
//  InsightsPanenView.swift
//  OranGo
//
//  Harvest insights section with numbered ranked items.
//

import SwiftUI

struct InsightsPanenView: View {
    let insights: [HarvestInsight]

    var placeholder: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insight panen")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)

            if let placeholder {
                Text(placeholder)
                    .font(.caption)
                    .foregroundStyle(Color.orangoTextSecondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(insights) { insight in
                        InsightItemRow(insight: insight)
                    }
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
