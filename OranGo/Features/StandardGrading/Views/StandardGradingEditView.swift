import SwiftUI

struct StandardGradingEditView: View {
    let rule: ThresholdRule?
    let viewModel: StandardGradingViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var retailGradeId: Int
    @State private var diameterMin: String
    @State private var diameterMax: String
    @State private var beratMin: String
    @State private var beratMax: String
    @State private var warnaOranye: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(rule: ThresholdRule?, viewModel: StandardGradingViewModel) {
        self.rule = rule
        self.viewModel = viewModel
        
        _retailGradeId = State(initialValue: rule?.retailGradeId ?? 1)
        _diameterMin = State(initialValue: rule?.diameterMin.map { String($0) } ?? "")
        _diameterMax = State(initialValue: rule?.diameterMaks.map { String($0) } ?? "")
        _beratMin = State(initialValue: rule?.beratMin.map { String($0) } ?? "")
        _beratMax = State(initialValue: rule?.beratMaks.map { String($0) } ?? "")
        _warnaOranye = State(initialValue: rule?.warnaOranye.map { String($0) } ?? "")
    }
    
    private var isEditing: Bool {
        rule != nil
    }
    
    private var title: String {
        isEditing ? "Edit Standar Grading" : "Tambah Standar Grading"
    }
    
    private var saveButtonTitle: String {
        isEditing ? "Simpan" : "Tambah Standar"
    }
    
    private var standardName: String {
        let retailName = viewModel.retailGradeNameById[retailGradeId] ?? "Retail - Jeruk Keprok"
        return "\(retailName)"
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
                            Text(standardName)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
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
        guard let diameterMinValue = Double(diameterMin),
              let diameterMaxValue = Double(diameterMax),
              let beratMinValue = Double(beratMin),
              let beratMaxValue = Double(beratMax),
              let warnaOranyeValue = Double(warnaOranye) else {
            errorMessage = "Pastikan semua nilai sudah valid."
            return
        }
        
        guard diameterMinValue <= diameterMaxValue else {
            errorMessage = "Ukuran minimal tidak boleh lebih besar dari ukuran maksimal."
            return
        }
        
        guard beratMinValue <= beratMaxValue else {
            errorMessage = "Berat minimal tidak boleh lebih besar dari berat maksimal."
            return
        }
        
        guard warnaOranyeValue >= 0 && warnaOranyeValue <= 100 else {
            errorMessage = "Warna permukaan harus berada antara 0% dan 100%."
            return
        }
        
        let thresholdRule = ThresholdRule(
            id: rule?.id ?? 0,
            retailGradeId: retailGradeId,
            diameterMin: diameterMinValue,
            diameterMaks: diameterMaxValue,
            beratMin: beratMinValue,
            beratMaks: beratMaxValue,
            warnaOranye: warnaOranyeValue
        )
        
        isSaving = true
        errorMessage = nil
        
        do {
            if isEditing {
                try await viewModel.updateThresholdRule(thresholdRule)
            } else {
                try await viewModel.createThresholdRule(thresholdRule)
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

#Preview("Edit - Superindo") {
    StandardGradingEditView(
        rule: ThresholdRule(
            id: 1,
            retailGradeId: 2,
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
        rule: nil,
        viewModel: StandardGradingViewModel()
    )
}
