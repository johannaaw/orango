//
//  DashboardViewModel.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation

/// ViewModel that drives the Dashboard screen.
/// TODO: Replace placeholder data with actual database / API fetches.
@Observable
final class DashboardViewModel {

    // MARK: - Published State

    /// Summary data displayed at the top of the dashboard.
    var summary: DashboardSummary = .sample

    /// Grade-level sorting results for the donut chart & breakdown.
    var gradeResults: [GradeResult] = GradeResult.sampleResults

    /// Harvest insight items.
    var insights: [HarvestInsight] = HarvestInsight.sampleInsights

    /// Daily sorting entries for the detail table.
    var sortingEntries: [SortingDayEntry] = SortingDayEntry.sampleEntries

    /// Currently selected date for filtering.
    var selectedDate: Date = .now

    /// Currently selected date range filter.
    var selectedDateFilter: DateFilter = .today

    /// Indices of expanded sorting day rows.
    var expandedDayIDs: Set<UUID> = []

    // MARK: - Actions

    /// Toggles the expanded/collapsed state of a sorting day row.
    func toggleExpansion(for entry: SortingDayEntry) {
        if expandedDayIDs.contains(entry.id) {
            expandedDayIDs.remove(entry.id)
        } else {
            expandedDayIDs.insert(entry.id)
        }
    }

    /// Returns whether a sorting day row is expanded.
    func isExpanded(_ entry: SortingDayEntry) -> Bool {
        expandedDayIDs.contains(entry.id)
    }

    /// Triggers a data export action.
    /// TODO: Implement actual export logic (CSV, PDF, etc.)
    func exportData() {
        print("Export triggered — implement export logic here")
    }

    /// Fetches dashboard data from the backend.
    /// TODO: Implement actual data fetching.
    func fetchData() async {
        // Placeholder — data is already set via sample values.
        // Replace with:
        // let data = try await APIService.shared.fetchDashboard(date: selectedDate, filter: selectedDateFilter)
        // self.summary = data.summary
        // self.gradeResults = data.gradeResults
        // self.insights = data.insights
        // self.sortingEntries = data.sortingEntries
    }
}
