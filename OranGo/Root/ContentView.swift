//
//  ContentView.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//
import SwiftUI

struct ContentView: View {
    @State private var selectedPage: Page? = .grading

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
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            switch selectedPage {
            case .dashboard:
                Text("Dashboard ini")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .grading:
                StandardGradingView()

            case nil:
                Text("Pilih halaman")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview("OranGo - iPad Landscape") {
    ContentView()
        .previewInterfaceOrientation(.landscapeLeft)
}
