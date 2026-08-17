//
//  DateFilterBarView.swift
//  OranGo
//
//  Date picker trigger, segmented date filter, and export button.
//

import SwiftUI

struct DateFilterBarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedFilter: DateFilter

    let exportFlow: ExportFlowModel

    let exportPayload: () -> ExportPayload

    var body: some View {
        HStack(spacing: 12) {
            datePicker
            rangePicker
            Spacer(minLength: 12)
            ExportControl(model: exportFlow, payload: exportPayload)
        }
    }

    // MARK: - Date + Range

    private var rangePicker: some View {
        Picker("Rentang waktu", selection: $selectedFilter) {
            ForEach(DateFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityLabel("Rentang waktu")
    }

    private var datePicker: some View {
        DatePicker(
            "Tanggal",
            selection: $selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .environment(\.locale, Locale(identifier: "id_ID"))
        .accessibilityLabel("Tanggal")
    }
}

// MARK: - Preview

#Preview {
    DateFilterBarView(
        selectedDate: .constant(.now),
        selectedFilter: .constant(.today),
        exportFlow: ExportFlowModel(),
        exportPayload: {
            ExportPayload(fileBaseName: "OranGo Contoh", csvRows: [["Grade"]]) {
                Text("Dokumen contoh").padding(40)
            }
        }
    )
    .padding()
    .background(Color.orangoPageBackground)
}
