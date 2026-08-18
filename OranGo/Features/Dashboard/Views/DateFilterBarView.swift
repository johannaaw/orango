//
//  DateFilterBarView.swift
//  OranGo
//
//  Date picker trigger, segmented period filter, and export button.
//

import SwiftUI

struct DateFilterBarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedFilter: DateFilter

    let activeRange: DateInterval

    let exportFlow: ExportFlowModel

    let exportPayload: () -> ExportPayload

    var body: some View {
        HStack(spacing: 12) {
            rangePicker
            PeriodPickerButton(
                selectedDate: $selectedDate,
                filter: selectedFilter,
                activeRange: activeRange
            )
            Spacer(minLength: 12)
            ExportControl(model: exportFlow, payload: exportPayload)
        }
    }

    // MARK: - Period

    private var rangePicker: some View {
        Picker("Periode", selection: $selectedFilter) {
            ForEach(DateFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityLabel("Periode")
    }
}

// MARK: - Preview

#Preview {
    DateFilterBarView(
        selectedDate: .constant(.now),
        selectedFilter: .constant(.daily),
        activeRange: DateFilter.daily.range(endingAt: .now),
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
