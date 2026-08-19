//
//  OranGoToast.swift
//  OranGo
//
//  Brief success banner, shown after a standard is saved.
//

import SwiftUI

struct OranGoToast: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.orangoStatusGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orangoTextPrimary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.orangoTextPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orangoStatusGreen.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orangoStatusGreen.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(message)")
    }
}

// MARK: - Presentation

extension View {
    /// Shows `toast` at the top of the screen and clears it after a short read.
    func oranGoToast(_ toast: Binding<OranGoToast.Content?>) -> some View {
        overlay(alignment: .top) {
            if let content = toast.wrappedValue {
                OranGoToast(title: content.title, message: content.message)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: content.id) {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(.snappy(duration: 0.25)) {
                            toast.wrappedValue = nil
                        }
                    }
            }
        }
        .animation(.snappy(duration: 0.25), value: toast.wrappedValue?.id)
    }
}

extension OranGoToast {
    struct Content: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
    }
}

// MARK: - Preview

#Preview {
    OranGoToast(
        title: "Standar Grading Disimpan!",
        message: "\"Superindo - Jeruk medan\" berhasil ditambahkan"
    )
    .padding()
    .background(Color.orangoPageBackground)
}
