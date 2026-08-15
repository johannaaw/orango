//
//  DashboardHeaderView.swift
//  OranGo
//
//  Dashboard header with title, machine status badge, and last-updated text.
//

import SwiftUI

/// Header section showing the dashboard title, machine badge, and refresh time.
struct DashboardHeaderView: View {
    let summary: DashboardSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row with badge
            HStack(spacing: 12) {
                Text("Dashboard")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                // Machine status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)

                    Text("\(summary.machineID) : \(summary.isActive ? "Terhubung" : "Tidak Terhubung")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(summary.isActive ? Color.orangoStatusGreen : Color.orangoTextSecondary)
                )
            }

            // Last updated
            Text("Terakhir diperbarui: \(summary.lastUpdated)")
                .font(.system(size: 13))
                .foregroundStyle(Color.orangoTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    DashboardHeaderView(summary: .sample)
        .padding()
}
