//
//  DashboardView.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var isShowingGradingInfo = false
    @State private var isShowingAddBatch = false
    @State private var exportFlow = ExportFlowModel()

    init(store: SortingStore) {
        _viewModel = State(initialValue: DashboardViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardHeaderView(summary: viewModel.summary)

                DateFilterBarView(
                    selectedDate: $viewModel.selectedDate,
                    selectedFilter: $viewModel.selectedDateFilter,
                    activeRange: viewModel.activeRange,
                    exportFlow: exportFlow,
                    exportPayload: { exportPayload }
                )

                GradeResultsCardView(
                    results: viewModel.gradeResults,
                    selectedGrade: viewModel.selectedGrade,
                    onSelect: { grade in
                        withAnimation(.snappy(duration: 0.25)) {
                            viewModel.selectGrade(grade)
                        }
                    }
                )
                
                SummaryCardsView(
                    weightKg: viewModel.displayedWeightKg,
                    count: viewModel.displayedCount,
                    gradeLabel: viewModel.displayedGradeLabel,
                    gradingStandard: viewModel.summary.gradingStandard,
                    totalBatch: viewModel.summary.totalBatch,
                    onGradingStandardInfo: { isShowingGradingInfo = true }
                )

                InsightsPanenView(insights: viewModel.insights)

                DetailSortingTableView(
                    entries: viewModel.sortingEntries,
                    expandedIDs: viewModel.expandedDayIDs,
                    onToggle: { entry in
                        withAnimation(.snappy(duration: 0.25)) {
                            viewModel.toggleExpansion(for: entry)
                        }
                    },
                    onAddBatch: { isShowingAddBatch = true }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.orangoPageBackground)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: BatchDetailRoute.self) { route in
            BatchDetailView(route: route)
        }
        .sheet(isPresented: $isShowingAddBatch) {
            AddBatchSheet(
                machines: viewModel.availableMachines,
                gradingStandards: viewModel.gradingStandards,
                onStart: { machine, standard in
                    try await viewModel.startBatch(machine: machine, standard: standard)
                }
            )
        }
        .alert("Standar Grading", isPresented: $isShowingGradingInfo) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text("Standar grading yang sedang dipakai mesin untuk menentukan grade setiap buah: \(viewModel.summary.gradingStandard).")
        }
        .task {
            viewModel.applyRange()
        }
        .onChange(of: viewModel.selectedDate) {
            viewModel.applyRange()
        }
        .onChange(of: viewModel.selectedDateFilter) {
            viewModel.applyRange()
        }
    }

    // MARK: - Export

    private var exportPayload: ExportPayload {
        let summary = viewModel.summary
        let results = viewModel.gradeResults
        let insights = viewModel.insights
        let entries = viewModel.sortingEntries
        let date = viewModel.selectedDate

        return ExportPayload(
            fileBaseName: "OranGo Dashboard \(date.formattedIndonesian)",
            csvRows: ExportPayload.gradeCSVRows(
                title: "Dashboard \(date.formattedIndonesian)",
                totalWeightKg: summary.totalWeightKg,
                totalCount: summary.totalCount,
                gradingStandard: summary.gradingStandard,
                results: results
            )
        ) {
            DashboardExportDocument(
                summary: summary,
                gradeResults: results,
                insights: insights,
                sortingEntries: entries,
                selectedDate: date
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DashboardView(store: SortingStore())
    }
    .environment(SortingStore())
}
