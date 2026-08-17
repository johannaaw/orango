//
//  DetailSortingTableView.swift
//  OranGo
//
//  Detail sorting table with column headers, expandable day rows, and horizontal paging.
//

import SwiftUI

// MARK: - Shared Metrics

enum SortingTableMetrics {
    static let trailingColumnWidth: CGFloat = 96
    static let rowHorizontalPadding: CGFloat = 16
    static let rowCornerRadius: CGFloat = 8
    static let nestedIndent: CGFloat = 16
    static let rowsPerPage = 5
}

// MARK: - Detail Sorting Table

struct DetailSortingTableView: View {
    let entries: [SortingDayEntry]
    let expandedIDs: Set<UUID>
    let onToggle: (SortingDayEntry) -> Void

    var onAddBatch: (() -> Void)? = nil

    @State private var currentPage: Int?

    private var pages: [[SortingDayEntry]] {
        entries.chunked(into: SortingTableMetrics.rowsPerPage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detail Sorting")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)

            columnHeaders

            Divider()
                .overlay(Color.orangoBorder)

            pagedRows

            if pages.count > 1 {
                pageIndicator
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
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

    // MARK: Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("Tanggal")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Total Sorting")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Total Batch")
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: SortingTableMetrics.trailingColumnWidth)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Color.orangoTextSecondary)
        .padding(.horizontal, SortingTableMetrics.rowHorizontalPadding)
        .accessibilityHidden(true)
    }

    // MARK: Paged Rows

    private var pagedRows: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 8) {
                        ForEach(page) { entry in
                            SortingDayRowView(
                                entry: entry,
                                isExpanded: expandedIDs.contains(entry.id),
                                onToggle: { onToggle(entry) },
                                onAddBatch: onAddBatch
                            )
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .containerRelativeFrame(.horizontal)
                    .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentPage)
        .accessibilityLabel("Detail sorting per tanggal")
        .accessibilityHint("Geser ke samping untuk melihat tanggal lainnya")
    }

    // MARK: Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { index in
                let isCurrent = index == (currentPage ?? 0)

                Button {
                    withAnimation(.snappy) { currentPage = index }
                } label: {
                    Circle()
                        .fill(isCurrent ? Color.orangoTextSecondary : Color.orangoTextTertiary.opacity(0.45))
                        .frame(width: 6, height: 6)
                        .frame(width: 16, height: 24)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Halaman \(index + 1)")
                .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 6)
        .background(Capsule().fill(Color.orangoRowBackground))
    }
}

// MARK: - Preview

#Preview {
    DetailSortingTableView(
        entries: SortingDayEntry.sampleEntries,
        expandedIDs: [SortingDayEntry.sampleEntries[1].id],
        onToggle: { _ in }
    )
    .padding()
    .background(Color.orangoPageBackground)
}
