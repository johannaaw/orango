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

    let onStart: (SortingMachine, GradingStandard) -> String?

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMachine: SortingMachine?
    @State private var selectedStandard: GradingStandard?
    @State private var startedBatchName: String?

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

            field(
                title: "Mesin Sorting",
                placeholder: "Pilih mesin untuk sorting",
                selection: selectedMachine?.name,
                isEmpty: machines.isEmpty,
                emptyMessage: "Semua mesin sedang dipakai"
            ) {
                ForEach(machines) { machine in
                    Button(machine.name) { selectedMachine = machine }
                }
            }

            field(
                title: "Standar Grading",
                placeholder: "Pilih standar grading",
                selection: selectedStandard?.name,
                isEmpty: gradingStandards.isEmpty,
                emptyMessage: "Belum ada standar grading"
            ) {
                ForEach(gradingStandards) { standard in
                    Button(standard.name) { selectedStandard = standard }
                }
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

    private func field<Options: View>(
        title: String,
        placeholder: String,
        selection: String?,
        isEmpty: Bool,
        emptyMessage: String,
        @ViewBuilder options: () -> Options
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            Menu {
                if isEmpty {
                    Text(emptyMessage)
                } else {
                    options()
                }
            } label: {
                HStack {
                    Text(selection ?? placeholder)
                        .font(.subheadline)
                        .foregroundStyle(selection == nil ? Color.orangoTextSecondary : Color.orangoTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.orangoTextSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orangoRowBackground)
                )
                .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isEmpty)
            .accessibilityLabel(title)
            .accessibilityValue(selection ?? "Belum dipilih")

            if isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(Color.orangoTextSecondary)
            }
        }
    }

    private var startButton: some View {
        Button {
            guard let selectedMachine, let selectedStandard else { return }
            let name = onStart(selectedMachine, selectedStandard)
            withAnimation(.snappy(duration: 0.2)) {
                startedBatchName = name ?? "baru"
            }
        } label: {
            Text("Mulai proses sorting")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canStart ? .white : Color.orangoTextTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule().fill(canStart ? Color.orangoBrandOrange : Color.orangoRowBackground)
                )
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
        .accessibilityHint(canStart ? "" : "Pilih mesin dan standar grading terlebih dahulu")
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
