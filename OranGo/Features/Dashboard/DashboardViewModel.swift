//
//  DashboardViewModel.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let store: SortingStore

    init(store: SortingStore) {
        self.store = store
    }

    // MARK: - Data (from the store)

    var summary: DashboardSummary { store.summary }
    var gradeResults: [GradeResult] { store.gradeResults }
    private(set) var insights: [HarvestInsight] = []
    private(set) var insightNotice: String?
    private(set) var isGeneratingInsights = false

    private var lastInsightSnapshot: InsightSnapshot?
    var sortingEntries: [SortingDayEntry] { store.sortingEntries }

    var availableMachines: [SortingMachine] { store.availableMachines }
    var gradingStandards: [GradingStandard] { store.gradingStandards }

    // MARK: - Screen State

    var selectedDate: Date = .now

    var selectedDateFilter: DateFilter = .daily

    var expandedDayIDs: Set<Date> = []

    var selectedGrade: GradeType?

    var activeRange: DateInterval { store.range }

    func applyRange() {
        store.setRange(selectedDateFilter.range(endingAt: selectedDate))
    }

    /// Insights are written by a language model, so they are refreshed when the period
    /// changes rather than on every 7-second data poll.
    var insightSnapshot: InsightSnapshot {
        InsightSnapshot(
            periodLabel: activeRange.formattedIndonesianRange,
            totalWeightKg: summary.totalWeightKg,
            totalCount: summary.totalCount,
            totalBatch: summary.totalBatch,
            gradeResults: gradeResults
        )
    }

    func refreshInsightsIfNeeded() async {
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

    // MARK: - Derived Summary Values

    private var selectedResult: GradeResult? {
        guard let selectedGrade else { return nil }
        return gradeResults.first { $0.gradeType == selectedGrade }
    }

    var displayedWeightKg: Double {
        selectedResult?.weightKg ?? summary.totalWeightKg
    }

    var displayedCount: Int {
        selectedResult?.count ?? summary.totalCount
    }

    var displayedGradeLabel: String {
        selectedGrade?.displayName ?? "Semua Grade"
    }

    // MARK: - Actions

    func selectGrade(_ grade: GradeType) {
        selectedGrade = (selectedGrade == grade) ? nil : grade
    }

    func toggleExpansion(for entry: SortingDayEntry) {
        if expandedDayIDs.contains(entry.id) {
            expandedDayIDs.remove(entry.id)
        } else {
            expandedDayIDs.insert(entry.id)
        }
    }

    func isExpanded(_ entry: SortingDayEntry) -> Bool {
        expandedDayIDs.contains(entry.id)
    }

    func startBatch(machine: SortingMachine, standard: GradingStandard) async throws -> String {
        let batch = try await store.startBatch(machine: machine, standard: standard)

        if let today = store.sortingEntries.first(where: \.isToday) {
            expandedDayIDs.insert(today.id)
        }
        return batch.name
    }

    func fetchData() async {
        applyRange()
        await store.load()
    }
}
