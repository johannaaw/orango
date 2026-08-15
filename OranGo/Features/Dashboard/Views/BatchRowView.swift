//
//  BatchRowView.swift
//  OranGo
//
//  Sub-row inside an expanded sorting day, showing batch name, weight, and detail button.
//

import SwiftUI

/// A single batch row displayed inside an expanded sorting day entry.
struct BatchRowView: View {
    let batch: BatchEntry

    /// Callback when the "Detail" button is tapped.
    /// TODO: Wire to navigation / detail sheet in the actual app.
    var onDetailTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Batch name
            Text(batch.name)
                .font(.system(size: 14))
                .foregroundStyle(Color.orangoTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 32)

            // Batch weight
            Text("\(Int(batch.weightKg)) kg")
                .font(.system(size: 14))
                .foregroundStyle(Color.orangoTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Spacer for "Total Batch" column
            Color.clear
                .frame(maxWidth: .infinity)

            // Detail button
            Button {
                onDetailTapped?()
            } label: {
                Text("Detail")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orangoBrandOrange)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.orangoCardBackground)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        BatchRowView(batch: BatchEntry(name: "Batch 1", weightKg: 330))
        Divider()
        BatchRowView(batch: BatchEntry(name: "Batch 2", weightKg: 350))
    }
    .padding()
}
