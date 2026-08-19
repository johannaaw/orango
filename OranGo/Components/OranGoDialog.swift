//
//  OranGoDialog.swift
//  OranGo
//
//  The app's own confirmation and blocked-action dialogs, presented as fitted sheets the
//  same way AddBatchSheet and EndSortingSheet are.
//

import SwiftUI

struct OranGoDialog: View {

    /// Some dialogs show a white glyph on a filled circle, others a plain tinted glyph.
    enum Emblem {
        case badge(systemName: String, color: Color)
        case glyph(systemName: String, color: Color)
    }

    let emblem: Emblem
    let title: String
    let message: String

    var confirmTitle: String = "OK"
    var cancelTitle: String? = nil
    var onConfirm: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            emblemView

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.orangoTextPrimary)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.orangoTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    onConfirm()
                } label: {
                    Text(confirmTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color.orangoBrandOrange))
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)

                if let cancelTitle {
                    Button {
                        dismiss()
                    } label: {
                        Text(cancelTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.orangoTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(Color.orangoRowBackground))
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
        .padding(28)
        .frame(width: 440)
        .presentationSizing(.fitted)
        .presentationBackground(Color.orangoCardBackground)
    }

    @ViewBuilder
    private var emblemView: some View {
        switch emblem {
        case .badge(let systemName, let color):
            ZStack {
                Circle().fill(color)

                Image(systemName: systemName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 66, height: 66)

        case .glyph(let systemName, let color):
            Image(systemName: systemName)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(color)
                .frame(height: 66)
        }
    }
}

// MARK: - Preview

#Preview("Tidak dapat menghapus") {
    OranGoDialog(
        emblem: .badge(systemName: "trash.slash.fill", color: Color.orangoDangerRed),
        title: "Tidak Dapat Menghapus Standar Grading",
        message: """
        Standar grading yang sedang aktif tidak dapat dihapus selama proses sorting berlangsung.
        Silahkan tunggu hingga proses selesai untuk melakukan perubahan.
        """
    )
}

#Preview("Konfirmasi hapus") {
    OranGoDialog(
        emblem: .badge(systemName: "exclamationmark", color: Color.orangoDangerRed),
        title: "Hapus Standar Grading Secara Permanen?",
        message: "Semua data akan dihapus secara permanen. Pastikan anda sudah benar-benar yakin.",
        confirmTitle: "Hapus",
        cancelTitle: "Batal"
    )
}

#Preview("Tidak dapat mengaktifkan") {
    OranGoDialog(
        emblem: .glyph(systemName: "exclamationmark.triangle.fill", color: Color.orangoBrandOrange),
        title: "Tidak Dapat Mengaktifkan Standar Grading",
        message: "Non-aktifkan standar grading yang sedang aktif terlebih dahulu sebelum mengaktifkan standar ini."
    )
}
