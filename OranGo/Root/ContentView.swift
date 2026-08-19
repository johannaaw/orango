//
//  ContentView.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(SortingStore.self) private var store
    @State private var selectedPage: Page? = .dashboard

    enum Page: Hashable {
        case dashboard
        case grading
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPage) {
                Section {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                        .tag(Page.dashboard)

                    Label("Standar Grading", systemImage: "slider.vertical.3")
                        .tag(Page.grading)
                }
            }
            // Drives the row selection and hover highlight, which is blue by default.
            .tint(Color.orangoBrandOrange)
            .navigationTitle("OranGo")
            .navigationSplitViewColumnWidth(
                min: 220,
                ideal: 240,
                max: 280
            )

        } detail: {
            switch selectedPage {
            case .dashboard:
                // The detail column of a NavigationSplitView does not supply a stack of its
                // own, so without this the "Detail" links have nothing to push onto.
                NavigationStack {
                    DashboardView(store: store)
                }

            case .grading:
                StandardGradingView()

            case nil:
                Text("Pilih halaman")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // One poller for the whole app, so every screen reads the same live figures.
        .task { store.startAutoRefresh() }
    }
}

#Preview {
    ContentView()
        .environment(SortingStore())
}
