import SwiftUI

struct StandardGradingEditView: View {
    let standard: RetailGrade?
    let viewModel: StandardGradingViewModel

    /// Reports the saved name so the list can raise its success toast.
    var onSaved: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var retailName: String
    @State private var diameterMin: String
    @State private var diameterMax: String
    @State private var beratMin: String
    @State private var beratMax: String
    @State private var warnaOranye: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        standard: RetailGrade?,
        viewModel: StandardGradingViewModel,
        onSaved: @escaping (String) -> Void = { _ in }
    ) {
        self.standard = standard
        self.viewModel = viewModel
        self.onSaved = onSaved

        _retailName = State(initialValue: standard?.retailName ?? "")
        _diameterMin = State(initialValue: standard?.diameterMin.map { String($0) } ?? "")
        _diameterMax = State(initialValue: standard?.diameterMaks.map { String($0) } ?? "")
        _beratMin = State(initialValue: standard?.beratMin.map { String($0) } ?? "")
        _beratMax = State(initialValue: standard?.beratMaks.map { String($0) } ?? "")
        _warnaOranye = State(initialValue: standard?.warnaOranye.map { String($0) } ?? "")
    }

    private var isEditing: Bool {
        standard != nil
    }

    private var title: String {
        isEditing ? "Edit Standar Grading" : "Tambah Standar Grading"
    }

    private var saveButtonTitle: String {
        isEditing ? "Simpan" : "Tambah Standar"
    }

    private var trimmedName: String {
        retailName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Standar Grading")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Tentukan rentang nilai parameter kualitas sesuai dengan standar retail")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Standar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Superindo - Jeruk Medan", text: $retailName)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        Text("Gunakan nama yang mudah dikenali, misalnya gabungan retail dan jenis buah.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Kriteria Buah yang Diterima")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(height: 1)
                        }
                        
                        // 1. Diameter Group
                        criteriaCard(
                            icon: "ruler",
                            title: "Diameter (cm)",
                            rows: [
                                ("Ukuran minimal", $diameterMin, "5.8"),
                                ("Ukuran maksimal", $diameterMax, "7.0")
                            ]
                        )
                        
                        // 2. Berat Group
                        criteriaCard(
                            icon: "scalemass.fill",
                            title: "Berat (gr)",
                            rows: [
                                ("Berat minimal", $beratMin, "115"),
                                ("Berat maksimal", $beratMax, "150")
                            ]
                        )
                        
                        // 3. Warna Permukaan Group
                        criteriaCard(
                            icon: "paintpalette.fill",
                            title: "Warna permukaan (%)",
                            rows: [
                                ("Warna oranye minimal", $warnaOranye, "90")
                            ]
                        )
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    
                    // MARK: - Save Action Button
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Batal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(minWidth: 100, minHeight: 46)
                                .padding(.horizontal, 16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(23)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 23)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)
                        
                        Button(action: {
                            Task {
                                await save()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(saveButtonTitle)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(minWidth: 140, minHeight: 46)
                            .padding(.horizontal, 16)
                            .background(Color.orange)
                            .cornerRadius(23)
                            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            // The bottom row already pairs Batal with the save button; a second back control
            // in the toolbar was the duplicate.
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    // MARK: - Card Component Builder
    @ViewBuilder
    private func criteriaCard(icon: String, title: String, rows: [(label: String, text: Binding<String>, placeholder: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(0..<rows.count, id: \.self) { index in
                    let row = rows[index]
                    HStack {
                        Text(row.label)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField(row.placeholder, text: row.text)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    
                    if index < rows.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func save() async {
        let draft: RetailGradeDraft

        do {
            draft = RetailGradeDraft(
                retailName: trimmedName,
                catatan: standard?.catatan,
                aktif: standard?.isActive ?? false,
                diameterMin: try RetailGradeDraft.number(diameterMin, field: "Ukuran minimal"),
                diameterMaks: try RetailGradeDraft.number(diameterMax, field: "Ukuran maksimal"),
                beratMin: try RetailGradeDraft.number(beratMin, field: "Berat minimal"),
                beratMaks: try RetailGradeDraft.number(beratMax, field: "Berat maksimal"),
                warnaOranye: try RetailGradeDraft.number(warnaOranye, field: "Warna oranye minimal")
            )

            try draft.validate(against: viewModel.retailGrades, excluding: standard?.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            if let standard {
                try await viewModel.updateRetailGrade(id: standard.id, draft: draft)
            } else {
                try await viewModel.createRetailGrade(draft)
            }

            onSaved(draft.retailName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

#Preview("Edit - Superindo") {
    StandardGradingEditView(
        standard: RetailGrade(
            id: 1,
            retailName: "Superindo - Jeruk Medan",
            diameterMin: 6.0,
            diameterMaks: 9.0,
            beratMin: 130.0,
            beratMaks: 160.0,
            warnaOranye: 90.0
        ),
        viewModel: StandardGradingViewModel()
    )
}

#Preview("Tambah - Standar Baru") {
    StandardGradingEditView(
        standard: nil,
        viewModel: StandardGradingViewModel()
    )
}
