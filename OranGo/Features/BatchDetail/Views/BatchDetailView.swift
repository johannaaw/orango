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

    private var detail: BatchDetail { store.detail(for: route) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SummaryCardsView(
                    weightKg: displayedWeightKg,
                    count: displayedCount,
                    gradeLabel: displayedGradeLabel,
                    gradingStandard: detail.gradingStandard,
                    onGradingStandardInfo: { isShowingGradingInfo = true }
                )

                GradeResultsCardView(
                    results: detail.gradeResults,
                    selectedGrade: selectedGrade,
                    onSelect: { grade in
                        withAnimation(.snappy(duration: 0.25)) { selectGrade(grade) }
                    }
                )

                InsightsPanenView(insights: detail.insights)

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
        let detail = self.detail

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
