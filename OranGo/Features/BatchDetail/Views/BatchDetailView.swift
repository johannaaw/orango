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

    @State private var insights: [HarvestInsight] = []
    @State private var insightNotice: String?
    @State private var isGeneratingInsights = false
    @State private var lastInsightSnapshot: InsightSnapshot?

    private var detail: BatchDetail { store.detail(for: route) }

    /// Insights for this batch alone, not the dashboard's period-wide ones.
    private var insightSnapshot: InsightSnapshot {
        InsightSnapshot(
            periodLabel: route.title,
            totalWeightKg: detail.totalWeightKg,
            totalCount: detail.totalCount,
            totalBatch: 1,
            gradeResults: detail.gradeResults
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
                    insights: insights,
                    notice: insightNotice,
                    isLoading: isGeneratingInsights
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
        let snapshot = insightSnapshot
        guard snapshot != lastInsightSnapshot else { return }

        // 1. CEGAH SPAM: Jangan mulai request baru jika AI masih berfikir (Throttle)
        // Ini krusial untuk batch yang sedang isOngoing (data masuk tiap detik)
        guard !isGeneratingInsights else { return }

        // 2. CEGAH ERROR: Jangan tembak AI kalau belum ada buah yang disortir
        guard snapshot.totalCount > 0 else {
            self.insights = []
            self.insightNotice = "Menunggu buah pertama disortir..."
            return
        }

        // 3. Kunci State
        lastInsightSnapshot = snapshot
        isGeneratingInsights = true
        
        defer { isGeneratingInsights = false }

        // 4. Eksekusi
        let result = await InsightService.insights(for: snapshot)
        
        // 5. Update UI
        self.insights = result.insights
        if case .computed(let reason) = result.source {
            self.insightNotice = reason
        } else {
            self.insightNotice = nil
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
        let detail = BatchDetail(
            route: self.detail.route,
            isOngoing: self.detail.isOngoing,
            totalWeightKg: self.detail.totalWeightKg,
            totalCount: self.detail.totalCount,
            gradingStandard: self.detail.gradingStandard,
            gradeResults: self.detail.gradeResults,
            insights: insights
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
