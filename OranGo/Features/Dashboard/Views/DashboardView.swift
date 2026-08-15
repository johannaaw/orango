//
//  DashboardView.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import SwiftUI

/// Main dashboard screen that composes all dashboard sections in a scrollable layout.
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 1. Header — title, machine badge, last updated
                DashboardHeaderView(summary: viewModel.summary)

                // 2. Date filter bar — date, segmented filter, export
                DateFilterBarView(
                    selectedDate: $viewModel.selectedDate,
                    selectedFilter: $viewModel.selectedDateFilter,
                    onExport: { viewModel.exportData() }
                )

                // 3. Summary cards — Total Berat, Total Jumlah, Standar Grading
                SummaryCardsView(summary: viewModel.summary)

                // 4. Grade results — donut chart + grade breakdown
                GradeResultsCardView(results: viewModel.gradeResults)

                // 5. Harvest insights
                InsightsPanenView(insights: viewModel.insights)

                // 6. Detail sorting table
                DetailSortingTableView(
                    entries: viewModel.sortingEntries,
                    expandedIDs: viewModel.expandedDayIDs,
                    onToggle: { entry in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.toggleExpansion(for: entry)
                        }
                    }
                )
            }
            .padding(24)
        }
        .background(Color.orangoPageBackground)
        .task {
            // TODO: Fetch data from database/API on appear.
            await viewModel.fetchData()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
