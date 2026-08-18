//
//  ExportDocumentViews.swift
//  OranGo
//
//  Print layouts fed to ImageRenderer for the PDF export and its preview thumbnail.
//

import SwiftUI

// MARK: - Dashboard Document

struct DashboardExportDocument: View {
    let summary: DashboardSummary
    let gradeResults: [GradeResult]
    let insights: [HarvestInsight]
    let sortingEntries: [SortingDayEntry]
    let selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                Text("\(summary.machineID) · \(selectedDate.formattedIndonesian)")
                    .font(.footnote)
                    .foregroundStyle(Color.orangoTextSecondary)
            }

            SummaryCardsView(
                weightKg: summary.totalWeightKg,
                count: summary.totalCount,
                gradeLabel: "Semua Grade",
                gradingStandard: summary.gradingStandard,
                totalBatch: summary.totalBatch
            )

            GradeResultsCardView(results: gradeResults)

            InsightsPanenView(insights: insights)

            SortingSummaryList(entries: sortingEntries)
        }
        .padding(24)
    }
}

// MARK: - Batch Document

struct BatchExportDocument: View {
    let detail: BatchDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(detail.route.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.orangoTextPrimary)

            SummaryCardsView(
                weightKg: detail.totalWeightKg,
                count: detail.totalCount,
                gradeLabel: "Semua Grade",
                gradingStandard: detail.gradingStandard
            )

            GradeResultsCardView(results: detail.gradeResults)

            InsightsPanenView(insights: detail.insights)
        }
        .padding(24)
    }
}

// MARK: - Flat Sorting List

private struct SortingSummaryList: View {
    let entries: [SortingDayEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detail Sorting")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)

            HStack(spacing: 0) {
                Text("Tanggal").frame(maxWidth: .infinity, alignment: .leading)
                Text("Total Sorting").frame(maxWidth: .infinity, alignment: .leading)
                Text("Total Batch").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color.orangoTextSecondary)
            .padding(.horizontal, SortingTableMetrics.rowHorizontalPadding)

            Divider().overlay(Color.orangoBorder)

            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    HStack(spacing: 0) {
                        Text(entry.date.formattedIndonesian)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(Int(entry.totalWeightKg)) kg")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(entry.totalBatch)")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(Color.orangoTextPrimary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, SortingTableMetrics.rowHorizontalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: SortingTableMetrics.rowCornerRadius)
                            .fill(Color.orangoRowBackground)
                    )
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
    ScrollView {
        BatchExportDocument(
            detail: .sample(for: BatchDetailRoute(
                batchID: 1,
                batchName: "Batch 1",
                date: .now
            ))
        )
        .frame(width: ExportService.documentWidth)
    }
    .background(Color.orangoPageBackground)
}
