//
//  AddBatchSheet.swift
//  OranGo
//
//  "Tambah Batch Baru" — pick a machine and a grading standard, then start sorting.
//

import SwiftUI

struct AddBatchSheet: View {
    let machines: [SortingMachine]
    let gradingStandards: [GradingStandard]

    let onStart: (SortingMachine, GradingStandard) async throws -> String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMachine: SortingMachine?
    @State private var selectedStandard: GradingStandard?
    @State private var startedBatchName: String?
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var canStart: Bool {
        selectedMachine != nil && selectedStandard != nil
    }

    var body: some View {
        Group {
            if let startedBatchName {
                startedConfirmation(batchName: startedBatchName)
            } else {
                form
            }
        }
        .frame(width: 460)
        .presentationSizing(.fitted)
        .presentationBackground(Color.orangoCardBackground)
    }

    // MARK: - Form

    private var form: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            picker(
                title: "Mesin Sorting",
                placeholder: "Pilih mesin untuk sorting",
                emptyMessage: "Semua mesin sedang dipakai",
                options: machines,
                selection: $selectedMachine,
                label: \.name
            )

            picker(
                title: "Standar Grading",
                placeholder: "Pilih standar grading",
                emptyMessage: "Belum ada standar grading",
                options: gradingStandards,
                selection: $selectedStandard,
                label: \.name
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.orangoDangerRed)
                    .fixedSize(horizontal: false, vertical: true)
            }

            startButton
                .padding(.top, 8)
        }
        .padding(24)
    }

    private var header: some View {
        ZStack {
            Text("Tambah Batch Baru")
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

    private func picker<Item: Hashable & Identifiable>(
        title: String,
        placeholder: String,
        emptyMessage: String,
        options: [Item],
        selection: Binding<Item?>,
        label: KeyPath<Item, String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            Picker(title, selection: selection) {
                Text(placeholder).tag(Item?.none)

                ForEach(options) { option in
                    Text(option[keyPath: label]).tag(Optional(option))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .disabled(options.isEmpty)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orangoRowBackground)
            )

            if options.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(Color.orangoTextSecondary)
            }
        }
    }

    private var startButton: some View {
        Button {
            start()
        } label: {
            Group {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text("Mulai proses sorting")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(canStart ? .white : Color.orangoTextTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(canStart ? Color.orangoBrandOrange : Color.orangoRowBackground)
            )
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!canStart || isWorking)
        .accessibilityHint(canStart ? "" : "Pilih mesin dan standar grading terlebih dahulu")
    }

    private func start() {
        guard let selectedMachine, let selectedStandard else { return }
        isWorking = true
        errorMessage = nil
        Task {
            defer { isWorking = false }
            do {
                let name = try await onStart(selectedMachine, selectedStandard)
                withAnimation(.snappy(duration: 0.2)) { startedBatchName = name }
            } catch {
                errorMessage = "Gagal memulai batch. \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Started Confirmation

    private func startedConfirmation(batchName: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Color.orangoStatusGreen)

            Text("Sorting \(batchName.lowercased()) dimulai")
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

#Preview("Kosong") {
    AddBatchSheet(
        machines: SortingMachine.samples,
        gradingStandards: GradingStandard.samples,
        onStart: { _, _ in "Batch 3" }
    )
}

#Preview("Semua mesin sibuk") {
    AddBatchSheet(
        machines: [],
        gradingStandards: GradingStandard.samples,
        onStart: { _, _ in "Batch 3" }
    )
}
