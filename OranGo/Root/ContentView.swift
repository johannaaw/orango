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
    @State private var hoveredPage: Page?

    enum Page: Hashable {
        case dashboard
        case grading
    }

    var body: some View {
        NavigationSplitView {
            sidebar
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

    // MARK: - Sidebar

    /// Plain rows rather than `List(selection:)`. The system's sidebar selection is drawn
    /// differently once the column loses focus, which is what turned the selected row black
    /// whenever something in the detail column was tapped. `selectedPage` already drove the
    /// detail switch on its own, so nothing is lost by owning the styling here.
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            sidebarRow(title: "Dashboard", systemImage: "chart.bar.fill", page: .dashboard)
            sidebarRow(title: "Standar Grading", systemImage: "slider.vertical.3", page: .grading)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangoSidebarBackground)
    }

    private func sidebarRow(title: String, systemImage: String, page: Page) -> some View {
        let isSelected = selectedPage == page

        return Button {
            selectedPage = page
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.orangoBrandOrange : Color.orangoTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rowBackground(for: page))
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hoveredPage = isHovering ? page : (hoveredPage == page ? nil : hoveredPage)
        }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func rowBackground(for page: Page) -> Color {
        if selectedPage == page { return Color.orangoBrandOrange.opacity(0.16) }
        if hoveredPage == page { return Color.orangoBrandOrange.opacity(0.08) }
        return .clear
    }
}

#Preview {
    ContentView()
        .environment(SortingStore())
}
