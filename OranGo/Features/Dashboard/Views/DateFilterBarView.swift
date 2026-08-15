//
//  DateFilterBarView.swift
//  OranGo
//
//  Date display, segmented date filter, and export button.
//

import SwiftUI

/// A horizontal bar with date display, segmented filter, and export button.
struct DateFilterBarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedFilter: DateFilter
    var onExport: () -> Void
    

    var body: some View {
        HStack(spacing: 16) {
            // Date display
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.orangoTextSecondary)

                Text(selectedDate.formattedShort)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.orangoTextPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orangoBorder, lineWidth: 1)
            )

            // Segmented filter
            HStack(spacing: 0) {
                ForEach(DateFilter.allCases) { filter in
                    let isSelected = (selectedFilter == filter)
                    let textColor = isSelected ? Color.orangoTextPrimary : Color.orangoTextSecondary
                    let bgColor = isSelected ? Color.orangoCardBackground : Color.clear
                    
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textColor) // Menggunakan variabel lokal
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(bgColor) // Menggunakan variabel lokal
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orangoPageBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orangoBorder, lineWidth: 1)
            )

            Spacer()

            // Export button
            Button(action: onExport) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))

                    Text("Export")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.orangoTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orangoBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    DateFilterBarView(
        selectedDate: .constant(.now),
        selectedFilter: .constant(.today), // Asumsi enum DateFilter memiliki case .today
        onExport: {}
    )
    .padding()
}
