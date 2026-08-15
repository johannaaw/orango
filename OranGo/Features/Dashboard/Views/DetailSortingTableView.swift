//
//  DetailSortingTableView.swift
//  OranGo
//
//  Detail sorting table with column headers and expandable day rows.
//

import SwiftUI

/// Section card with the sorting detail table header and list of expandable day rows.
struct DetailSortingTableView: View {
    let entries: [SortingDayEntry]
    let expandedIDs: Set<UUID>
    let onToggle: (SortingDayEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Detail Sorting")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            // Column headers
            HStack(spacing: 0) {
                Text("Tanggal")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Total Sorting")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Total Batch")
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Spacer for chevron column
                Color.clear
                    .frame(width: 24)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.orangoTextSecondary)
            .padding(.horizontal, 16)

            Divider()
                .foregroundStyle(Color.orangoBorder)

            // Day rows
            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    SortingDayRowView(
                        entry: entry,
                        isExpanded: expandedIDs.contains(entry.id),
                        onToggle: { onToggle(entry) }
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangoCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orangoBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    DetailSortingTableView(
        entries: SortingDayEntry.sampleEntries,
        expandedIDs: [SortingDayEntry.sampleEntries[0].id],
        onToggle: { _ in }
    )
    .padding()
    .background(Color.orangoPageBackground)
}
