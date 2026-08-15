//
//  SortingDayRowView.swift
//  OranGo
//
//  Expandable row for a single sorting day in the detail table.
//

import SwiftUI

/// An expandable row showing a day's sorting summary.
/// When expanded, displays the individual batch sub-rows.
struct SortingDayRowView: View {
    let entry: SortingDayEntry
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main summary row
            Button(action: onToggle) {
                HStack(spacing: 0) {
                    // Date
                    Text(entry.date.formattedIndonesian)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orangoTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Total sorting weight
                    Text("\(Int(entry.totalWeightKg)) kg")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.orangoTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Total batch count
                    Text("\(entry.totalBatch)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.orangoTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orangoTextSecondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    isExpanded
                        ? Color.orangoBrandOrange.opacity(0.06)
                        : Color.orangoCardBackground
                )
            }
            .buttonStyle(.plain)

            // Expanded batch rows
            if isExpanded && !entry.batches.isEmpty {
                Divider()
                    .foregroundStyle(Color.orangoBorder)

                ForEach(entry.batches) { batch in
                    BatchRowView(batch: batch) {
                        // TODO: Navigate to batch detail screen
                        print("Detail tapped for \(batch.name)")
                    }

                    if batch.id != entry.batches.last?.id {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isExpanded ? Color.orangoBrandOrange.opacity(0.3) : Color.orangoBorder,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SortingDayRowView(
            entry: SortingDayEntry.sampleEntries[0],
            isExpanded: true,
            onToggle: {}
        )

        SortingDayRowView(
            entry: SortingDayEntry.sampleEntries[2],
            isExpanded: false,
            onToggle: {}
        )
    }
    .padding()
    .background(Color.orangoPageBackground)
}
