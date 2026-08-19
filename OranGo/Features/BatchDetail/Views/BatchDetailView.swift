//
//  BatchDetailView.swift
//  OranGo
//
//  Detail screen for a single batch, pushed from the Detail Sorting table.
//

import SwiftUI

struct BatchDetailView: View {
    let route: BatchDetailRoute

    @Environment(SortingStore.self) private var store

    @State private var selectedGrade: GradeType?
    @State private var isShowingGradingInfo = false
    @State private var isShowingEndSorting = false
    @State private var exportFlow = ExportFlowModel()

    @State private var insightsModel = InsightsModel()

    private var detail: BatchDetail { store.detail(for: route) }

    /// Insights for this batch alone, not the dashboard's period-wide ones.
    private var insightSnapshot: InsightSnapshot {
        InsightSnapshot(
            periodLabel: route.title,
            totalWeightKg: detail.totalWeightKg,
            totalCount: detail.totalCount,
            totalBatch: 1,
            gradeResults: detail.gradeResults,
            // A single batch has no earlier equivalent to compare against.
            comparison: nil,
            rejectBreakdown: detail.rejectBreakdown,
            throughputPerHour: detail.throughputPerHour
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GradeResultsCardView(
                    results: detail.gradeResults,
                    selectedGrade: selectedGrade,
                    onSelect: { grade in
                        withAnimation(.snappy(duration: 0.25)) { selectGrade(grade) }
                    }
                )

                SummaryCardsView(
                    weightKg: displayedWeightKg,
                    count: displayedCount,
                    gradeLabel: displayedGradeLabel,
                    gradingStandard: detail.gradingStandard,
                    onGradingStandardInfo: { isShowingGradingInfo = true }
                )

                InsightsPanenView(
                    insights: insightsModel.insights,
                    notice: insightsModel.notice,
                    isLoading: insightsModel.isGenerating
                )

                if detail.isOngoing {
                    endSortingButton
                        .padding(.top, 20)
                }
            }
            .padding(24)
        }
        .background(Color.orangoPageBackground)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshInsightsIfNeeded() }
        .onChange(of: insightSnapshot) {
            Task { await refreshInsightsIfNeeded() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ExportControl(
                    model: exportFlow,
                    payload: { exportPayload },
                    isEnabled: !detail.isOngoing
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .alert("Standar Grading", isPresented: $isShowingGradingInfo) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text("Standar grading yang sedang dipakai mesin untuk menentukan grade setiap buah: \(detail.gradingStandard).")
        }
        .sheet(isPresented: $isShowingEndSorting) {
            EndSortingSheet {
                try await store.finishBatch(id: route.batchID)
            }
        }
    }

    // MARK: - Insights

    private func refreshInsightsIfNeeded() async {
        await insightsModel.refresh(for: insightSnapshot)
    }

    // MARK: - Derived Values

    private var selectedResult: GradeResult? {
        guard let selectedGrade else { return nil }
        return detail.gradeResults.first { $0.gradeType == selectedGrade }
    }

    private var displayedWeightKg: Double { selectedResult?.weightKg ?? detail.totalWeightKg }
    private var displayedCount: Int { selectedResult?.count ?? detail.totalCount }
    private var displayedGradeLabel: String { selectedGrade?.displayName ?? "Semua Grade" }

    private func selectGrade(_ grade: GradeType) {
        selectedGrade = (selectedGrade == grade) ? nil : grade
    }

    // MARK: - End Sorting

    private var endSortingButton: some View {
        Button {
            isShowingEndSorting = true
        } label: {
            Text("Akhiri proses sorting")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.orangoDangerRed))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 40)
    }

    // MARK: - Export

    private var exportPayload: ExportPayload {
        let detail = BatchDetail(
            route: self.detail.route,
            isOngoing: self.detail.isOngoing,
            totalWeightKg: self.detail.totalWeightKg,
            totalCount: self.detail.totalCount,
            gradingStandard: self.detail.gradingStandard,
            gradeResults: self.detail.gradeResults,
            insights: insightsModel.insights
        )

        return ExportPayload(
            fileBaseName: "OranGo \(detail.route.title)",
            csvRows: ExportPayload.gradeCSVRows(
                title: detail.route.title,
                totalWeightKg: detail.totalWeightKg,
                totalCount: detail.totalCount,
                gradingStandard: detail.gradingStandard,
                results: detail.gradeResults
            )
        ) {
            BatchExportDocument(detail: detail)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BatchDetailView(
            route: BatchDetailRoute(batchID: 1, batchName: "Batch 1", date: .now)
        )
    }
    .environment(SortingStore())
}
