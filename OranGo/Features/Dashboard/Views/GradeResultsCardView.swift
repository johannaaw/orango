//
//  GradeResultsCardView.swift
//  OranGo
//
//  Card section showing donut chart and grade breakdown items.
//

import SwiftUI

struct GradeResultsCardView: View {
    let results: [GradeResult]

    var selectedGrade: GradeType? = nil

    var onSelect: ((GradeType) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hasil sorting berdasarkan grade")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)

            HStack(alignment: .center, spacing: 0) {
                DonutChartView(
                    results: results,
                    selectedGrade: selectedGrade,
                    onSelect: onSelect
                )
                .frame(width: 180, height: 180)
                .padding(.trailing, 24)

                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    if index > 0 {
                        Divider()
                            .frame(height: 120)
                            .overlay(Color.orangoBorder)
                    }

                    GradeItemView(
                        result: result,
                        isSelected: selectedGrade == result.gradeType,
                        isDimmed: isDimmed(result.gradeType),
                        onTap: { onSelect?(result.gradeType) }
                    )
                }
            }
            .frame(maxWidth: .infinity)
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

    private func isDimmed(_ grade: GradeType) -> Bool {
        guard let selectedGrade else { return false }
        return grade != selectedGrade
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GradeResultsCardView(results: GradeResult.sampleResults)
        GradeResultsCardView(results: GradeResult.sampleResults, selectedGrade: .gradeB)
    }
    .padding()
    .background(Color.orangoPageBackground)
}
