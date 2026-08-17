//
//  DashboardHeaderView.swift
//  OranGo
//
//  Dashboard header with title, machine status badge, and last-updated text.
//

import SwiftUI

struct DashboardHeaderView: View {
    let summary: DashboardSummary

    private var statusText: String {
        summary.isActive ? "Terhubung" : "Tidak Terhubung"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Text("Dashboard")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.orangoTextPrimary)

                machineBadge
            }

            Text("Terakhir diperbarui: \(summary.lastUpdated)")
                .font(.footnote)
                .foregroundStyle(Color.orangoTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machineBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)

            Text("\(summary.machineID) : \(statusText)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(summary.isActive ? Color.orangoStatusGreen : Color.orangoTextSecondary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status mesin \(summary.machineID)")
        .accessibilityValue(statusText)
    }
}

// MARK: - Preview

#Preview {
    DashboardHeaderView(summary: .sample)
        .padding()
}
