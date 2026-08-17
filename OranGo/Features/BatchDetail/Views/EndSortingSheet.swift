//
//  EndSortingSheet.swift
//  OranGo
//
//  Confirms ending a running batch, then reports that the run finished.
//

import SwiftUI

struct EndSortingSheet: View {
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var didFinish = false

    var body: some View {
        Group {
            if didFinish {
                finishedConfirmation
            } else {
                confirmation
            }
        }
        .frame(width: 460)
        .presentationSizing(.fitted)
        .presentationBackground(Color.orangoCardBackground)
    }

    // MARK: - Confirmation

    private var confirmation: some View {
        VStack(spacing: 20) {
            header

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.orangoDangerRed)

            Text("Anda yakin ingin mengakhiri proses sorting?\nTindakan ini tidak bisa dibatalkan")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.orangoTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onConfirm()
                withAnimation(.snappy(duration: 0.2)) { didFinish = true }
            } label: {
                Text("Ya, akhiri proses sorting")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.orangoBrandOrange))
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(24)
    }

    private var header: some View {
        ZStack {
            Text("Akhiri proses sorting")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.orangoTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.orangoRowBackground))
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tutup")
            }
        }
    }

    // MARK: - Finished

    private var finishedConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Color.orangoStatusGreen)

            Text("Proses sorting selesai")
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    EndSortingSheet(onConfirm: {})
}
