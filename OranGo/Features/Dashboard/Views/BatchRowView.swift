//
//  BatchRowView.swift
//  OranGo
//
//  Sub-row inside an expanded sorting day, showing batch name, weight, and detail button.
//

import SwiftUI

struct BatchRowView: View {
    let batch: BatchEntry

    let date: Date

    private var route: BatchDetailRoute {
        BatchDetailRoute(batchID: batch.id, batchName: batch.name, date: date)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(batch.name)
                .font(.subheadline)
                .padding(.leading, SortingTableMetrics.nestedIndent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(batch.isOngoing ? "Sedang proses sorting" : "\(Int(batch.weightKg ?? 0)) kg")
                .font(.subheadline)
                .foregroundStyle(batch.isOngoing ? Color.orangoTextSecondary : Color.orangoTextPrimary)
                .padding(.leading, SortingTableMetrics.nestedIndent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(maxWidth: .infinity)

            detailButton
                .frame(width: SortingTableMetrics.trailingColumnWidth, alignment: .trailing)
        }
        .foregroundStyle(Color.orangoTextPrimary)
        .padding(.vertical, 8)
        .padding(.horizontal, SortingTableMetrics.rowHorizontalPadding)
        .frame(minHeight: 48)
    }

    private var detailButton: some View {
        NavigationLink(value: route) {
            Text("Detail")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .frame(minHeight: 32)
                .background(Capsule().fill(Color.orangoBrandOrange))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lihat detail \(batch.name)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            BatchRowView(batch: BatchEntry(id: 1, name: "Batch 1", weightKg: 330), date: .now)
            BatchRowView(batch: BatchEntry(id: 2, name: "Batch 2", weightKg: 350), date: .now)
            BatchRowView(
                batch: BatchEntry(id: 3, name: "Batch 3", weightKg: nil, status: .ongoing),
                date: .now
            )
        }
        .padding()
        .background(Color.orangoCardBackground)
    }
}
