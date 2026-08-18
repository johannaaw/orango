//
//  SortingDayRowView.swift
//  OranGo
//
//  Expandable row for a single sorting day in the detail table.
//

import SwiftUI

struct SortingDayRowView: View {
    let entry: SortingDayEntry
    let isExpanded: Bool
    let onToggle: () -> Void

    var onAddBatch: (() -> Void)? = nil

    private var textColor: Color {
        entry.isToday ? Color.orangoBrandOrange : Color.orangoTextPrimary
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryRow

            if isExpanded {
                ForEach(entry.batches) { batch in
                    BatchRowView(batch: batch, date: entry.date)
                }

                if entry.isToday, let onAddBatch {
                    addBatchButton(action: onAddBatch)
                }
            }
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        Button(action: onToggle) {
            HStack(spacing: 0) {
                Text(entry.date.formattedIndonesian)
                    .font(.subheadline.weight(entry.isToday ? .semibold : .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(Int(entry.totalWeightKg)) kg")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(entry.totalBatch)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orangoTextSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: SortingTableMetrics.trailingColumnWidth, alignment: .trailing)
            }
            .foregroundStyle(textColor)
            .padding(.vertical, 12)
            .padding(.horizontal, SortingTableMetrics.rowHorizontalPadding)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: SortingTableMetrics.rowCornerRadius)
                    .fill(isExpanded ? Color.orangoRowHighlight : Color.orangoRowBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: SortingTableMetrics.rowCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.isToday
            ? "Hari ini, \(entry.date.formattedIndonesian)"
            : entry.date.formattedIndonesian)
        .accessibilityValue("\(Int(entry.totalWeightKg)) kilogram, \(entry.totalBatch) batch")
        .accessibilityHint(isExpanded ? "Ketuk untuk menutup daftar batch" : "Ketuk untuk melihat daftar batch")
        .accessibilityAddTraits(isExpanded ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Add Batch

    private func addBatchButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.footnote.weight(.semibold))

                Text("Tambah batch baru")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.orangoBrandOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Capsule().stroke(Color.orangoBrandOrange, lineWidth: 1)
            )
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .accessibilityLabel("Tambah batch baru")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 8) {
            SortingDayRowView(
                entry: SortingDayEntry.sampleEntries[0],
                isExpanded: true,
                onToggle: {},
                onAddBatch: {}
            )

            SortingDayRowView(
                entry: SortingDayEntry.sampleEntries[2],
                isExpanded: false,
                onToggle: {}
            )
        }
        .padding()
        .background(Color.orangoCardBackground)
    }
}
