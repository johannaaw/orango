//
//  ContentView.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//
import SwiftUI

// MARK: - Navigation Destination

enum NavigationDestination: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case standardGrading = "Standar Grading"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .standardGrading: return "slider.horizontal.3"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Environment(SortingStore.self) private var store
    @State private var selectedDestination: NavigationDestination? = .dashboard

    var body: some View {
        NavigationSplitView {
            // MARK: Sidebar
            sidebarList
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            // MARK: Detail
            NavigationStack {
                detailContent
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.orangoBrandOrange)
        .task { store.startAutoRefresh() }
    }

    // MARK: - Sidebar

    private var sidebarList: some View {
        List(selection: $selectedDestination) {
            ForEach(NavigationDestination.allCases) { destination in
                Label(destination.rawValue, systemImage: destination.iconName)
                    .foregroundStyle(
                        selectedDestination == destination
                            ? Color.orangoBrandOrange
                            : Color.orangoTextSecondary
                    )
                    .tag(destination)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("OranGo")
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView(store: store)
        case .standardGrading, .none:
            StandardGradingView()
                .background(Color.orangoPageBackground)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
