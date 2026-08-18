//
//  ExportControl.swift
//  OranGo
//
//  The Export button and its three-step popover: pick a format, confirm, done.
//

import SwiftUI

// MARK: - Export Flow Model

@Observable
@MainActor
final class ExportFlowModel {
    enum Step: Equatable {
        case chooseFormat
        case confirm(ExportFormat)
        case saved
    }

    var isPresented = false
    var step: Step = .chooseFormat
    var previewImage: Image?
    var isWriting = false
    var errorMessage: String?

    static let savedDismissDelay: Duration = .seconds(1.8)

    // MARK: Actions

    func start() {
        step = .chooseFormat
        previewImage = nil
        isPresented = true
    }

    func select(_ format: ExportFormat, payload: @escaping () -> ExportPayload) {
        withAnimation(.snappy(duration: 0.2)) {
            step = .confirm(format)
        }

        guard format == .pdf else { return }
        Task {
            previewImage = ExportService.previewImage(of: payload())
        }
    }

    func write(_ format: ExportFormat, payload: @escaping () -> ExportPayload) {
        isWriting = true
        Task {
            defer { isWriting = false }
            do {
                _ = try ExportService.export(payload(), as: format)
                withAnimation(.snappy(duration: 0.2)) {
                    step = .saved
                }
            } catch {
                isPresented = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Export Control

struct ExportControl: View {
    @Bindable var model: ExportFlowModel

    let payload: () -> ExportPayload

    var isEnabled: Bool = true

    var body: some View {
        Button {
            model.start()
        } label: {
            Text("Export")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isEnabled ? Color.orangoTextPrimary : Color.orangoTextTertiary)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(Capsule().fill(Color.orangoCardBackground))
                .overlay(Capsule().stroke(Color.orangoBorder, lineWidth: 1))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Export")
        .accessibilityHint(isEnabled
            ? "Menyimpan tampilan ini sebagai PDF atau CSV"
            : "Tersedia setelah proses sorting selesai")
        .popover(isPresented: $model.isPresented) {
            popoverContent
                .presentationCompactAdaptation(.popover)
        }
        .alert("Export gagal", isPresented: errorBinding) {
            Button("Tutup", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    // MARK: - Popover

    @ViewBuilder
    private var popoverContent: some View {
        switch model.step {
        case .chooseFormat: formatPicker
        case .confirm(let format): confirmation(for: format)
        case .saved: savedConfirmation
        }
    }

    // MARK: Step 1 — pick a format

    private var formatPicker: some View {
        VStack(spacing: 0) {
            Text("Export sebagai")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)
                .padding(.vertical, 14)

            ForEach(ExportFormat.allCases) { format in
                Divider()

                Button {
                    model.select(format, payload: payload)
                } label: {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 260)
    }

    // MARK: Step 2 — confirm

    private func confirmation(for format: ExportFormat) -> some View {
        VStack(spacing: 16) {
            Text(format.confirmationTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            preview(for: format)

            Button {
                model.write(format, payload: payload)
            } label: {
                Group {
                    if model.isWriting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Export")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Capsule().fill(Color.orangoBrandOrange))
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(model.isWriting)
        }
        .padding(20)
        .frame(width: 320)
    }

    @ViewBuilder
    private func preview(for format: ExportFormat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orangoCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orangoBorder, lineWidth: 1)
                )

            switch format {
            case .pdf:
                if let previewImage = model.previewImage {
                    previewImage
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ProgressView()
                }
            case .csv:
                Image(systemName: format.iconName)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.orangoTextTertiary)
            }
        }
        .frame(height: 150)
        .accessibilityHidden(true)
    }

    // MARK: Step 3 — saved

    private var savedConfirmation: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.orangoStatusGreen)

            Text("File Tersimpan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orangoTextPrimary)

            Text("Tersimpan di Files › OranGo")
                .font(.caption)
                .foregroundStyle(Color.orangoTextSecondary)
        }
        .padding(24)
        .frame(width: 260)
        .accessibilityElement(children: .combine)
        .task {
            try? await Task.sleep(for: ExportFlowModel.savedDismissDelay)
            model.isPresented = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var model = ExportFlowModel()

    ExportControl(model: model) {
        ExportPayload(fileBaseName: "OranGo Contoh", csvRows: [["Grade", "Berat"]]) {
            Text("Dokumen contoh").padding(40)
        }
    }
    .padding()
    .background(Color.orangoPageBackground)
}
