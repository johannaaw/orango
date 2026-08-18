import SwiftUI

struct StandardGradingEditView: View {
    let rule: ThresholdRule?
    let viewModel: StandardGradingViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var retailGradeId: Int
    @State private var gradeId: Int
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
        _gradeId = State(initialValue: rule?.gradeId ?? 1)
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
        isEditing ? "Perbarui" : "Simpan"
    }

    private var standardName: String {
        let retailName = viewModel.retailGradeNameById[retailGradeId] ?? "Retail"
        let fruitName = viewModel.gradeNameById[gradeId] ?? "Jeruk Medan"
        return "\(retailName) - \(fruitName)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nama Standar") {
                    HStack {
                        Text("Nama standar")
                        Spacer()
                        Text(standardName)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Kriteria Buah yang Diterima") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Diameter (cm)")
                            .font(.headline)

                        HStack {
                            Text("Ukuran minimal")
                            Spacer()
                            TextField("Min", text: $diameterMin)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Ukuran maksimal")
                            Spacer()
                            TextField("Max", text: $diameterMax)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Berat (gr)")
                            .font(.headline)

                        HStack {
                            Text("Berat minimal")
                            Spacer()
                            TextField("Min", text: $beratMin)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Berat maksimal")
                            Spacer()
                            TextField("Max", text: $beratMax)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Warna Permukaan (%)")
                            .font(.headline)

                        HStack {
                            Text("Minimum")
                            Spacer()
                            TextField("Minimum %", text: $warnaOranye)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
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
            gradeId: gradeId,
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
            gradeId: 2,
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
