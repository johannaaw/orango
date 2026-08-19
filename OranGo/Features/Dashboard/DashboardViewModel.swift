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
    var sortingEntries: [SortingDayEntry] { store.sortingEntries }
    var loadError: String? { store.lastError }

    private let insightsModel = InsightsModel()

    var insights: [HarvestInsight] { insightsModel.insights }
    var insightNotice: String? { insightsModel.notice }
    var isGeneratingInsights: Bool { insightsModel.isGenerating }
    /// The figures the shown insights were written from, not the newest poll.
    var insightBasis: InsightSnapshot? { insightsModel.generatedFrom }

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
            gradeResults: gradeResults,
            comparison: store.comparison,
            rejectBreakdown: store.rejectBreakdown,
            throughputPerHour: store.throughputPerHour,
            batchQuality: store.batchQuality
        )
    }

    func refreshInsightsIfNeeded() async {
        await insightsModel.refresh(for: insightSnapshot)
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

    /// The store polls on its own; this is for pull-to-refresh, which should not have to
    /// wait out the interval.
    func reload() async {
        applyRange()
        await store.load()
    }
}
