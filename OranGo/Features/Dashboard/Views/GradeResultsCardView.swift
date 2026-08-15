//
//  GradeResultsCardView.swift
//  OranGo
//
//  Card section showing donut chart and grade breakdown items.
//

import SwiftUI

/// Section card combining the donut chart with grade breakdown items.
struct GradeResultsCardView: View {
    let results: [GradeResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Hasil sorting berdasarkan grade")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            // Content: chart + breakdown
            HStack(alignment: .center, spacing: 24) {
                // Donut chart
                DonutChartView(results: results)
                    .frame(width: 180, height: 180)
                
                Spacer()
                // Grade breakdown items
                HStack(spacing: 60) {
                    ForEach(results) { result in
                        GradeItemView(result: result)
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

// MARK: - Preview

#Preview {
    GradeResultsCardView(results: GradeResult.sampleResults)
        .padding()
        .background(Color.orangoPageBackground)
}
