//
//  ContentView.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//

import SwiftUI

// MARK: - Navigation Destination

/// The available navigation destinations in the sidebar.
enum NavigationDestination: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case standardGrading = "Standar Grading"

    var id: String { rawValue }

    /// SF Symbol icon for the sidebar item.
    var iconName: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .standardGrading: return "slider.horizontal.3"
        }
    }
}

// MARK: - Content View

/// Root view with a sidebar navigation and detail content area.
struct ContentView: View {
    @State private var selectedDestination: NavigationDestination = .dashboard

    var body: some View {
        NavigationSplitView {
            // MARK: Sidebar
            sidebarContent
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            // MARK: Detail
            switch selectedDestination {
            case .dashboard:
                DashboardView()
            case .standardGrading:
                // TODO: Replace with StandardGradingView when implemented.
                Text("Standar Grading")
                    .font(.title2)
                    .foregroundStyle(Color.orangoTextSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.orangoPageBackground)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Sidebar Content

    @ViewBuilder
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo header
            HStack(spacing: 8) {
                // Logo placeholder
                // TODO: Replace with actual OranGo logo asset.
                Circle()
                    .fill(Color.orangoBrandOrange)
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(Color.orangoBrandOrange)
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(Color.orangoBrandOrange)
                    .frame(width: 10, height: 10)

                Text("OranGo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                Spacer()

                Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.orangoTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Divider()
                .foregroundStyle(Color.orangoBorder)

            // Navigation items
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

/// A single clickable navigation item in the sidebar.
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
