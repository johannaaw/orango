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
    @State private var selectedDestination: NavigationDestination = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: Sidebar
            sidebarContent
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            // MARK: Detail
            NavigationStack {
                detailContent
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if columnVisibility == .detailOnly {
                    reopenSidebarBar
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Reopen Sidebar

    private var reopenSidebarBar: some View {
        HStack {
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    columnVisibility = .all
                }
            } label: {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.orangoTextSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buka sidebar")

            Spacer()
        }
        .padding(.leading, 12)
        .background(Color.orangoPageBackground)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView(store: store)
        case .standardGrading:
            Text("Standar Grading")
                .font(.title2)
                .foregroundStyle(Color.orangoTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.orangoPageBackground)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sidebar Content

    @ViewBuilder
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("OranGo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                Spacer()

                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        columnVisibility = .detailOnly
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.orangoTextSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tutup sidebar")
            }
            .padding(.leading, 16)
            .padding(.trailing, 4)
            .padding(.vertical, 12)

            Divider()
                .foregroundStyle(Color.orangoBorder)

            VStack(spacing: 4) {
                ForEach(NavigationDestination.allCases) { destination in
                    SidebarNavItem(
                        destination: destination,
                        isSelected: selectedDestination == destination
                    ) {
                        selectedDestination = destination
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Spacer()
        }
        .background(Color.orangoSidebarBackground)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}

// MARK: - Sidebar Navigation Item

private struct SidebarNavItem: View {
    let destination: NavigationDestination
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: destination.iconName)
                    .font(.system(size: 15))
                    .frame(width: 20)

                Text(destination.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                Spacer()
            }
            .foregroundStyle(isSelected ? Color.orangoBrandOrange : Color.orangoTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orangoBrandOrange.opacity(0.08))
                    : nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
