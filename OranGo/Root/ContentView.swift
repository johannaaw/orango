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
            .navigationTitle("OranGo")
            .navigationSplitViewColumnWidth(
                min: 220,
                ideal: 240,
                max: 280
            )

        } detail: {
            switch selectedPage {
            case .dashboard:
                DashboardView(store: store)

            case .grading:
                StandardGradingView()

            case nil:
                Text("Pilih halaman")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(SortingStore())
}
