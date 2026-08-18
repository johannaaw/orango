//
//  PeriodPickerButton.swift
//  OranGo
//
//  The date control, which changes shape with the selected period.
//

import SwiftUI

struct PeriodPickerButton: View {
    @Binding var selectedDate: Date
    let filter: DateFilter
    let activeRange: DateInterval

    @State private var isShowingCalendar = false
    @State private var isShowingMonthPicker = false

    var body: some View {
        switch filter {
        case .daily, .weekly:
            rangeButton
        case .monthly:
            monthButton
        }
    }

    // MARK: - Harian & Mingguan

    private var rangeButton: some View {
        chrome(icon: "calendar", text: activeRange.formattedIndonesianRange) {
            isShowingCalendar = true
        }
        .accessibilityLabel(filter == .daily ? "Tanggal" : "Rentang tanggal")
        .accessibilityValue(activeRange.formattedIndonesianRange)
        .popover(isPresented: $isShowingCalendar) {
            RangeCalendarView(selectedDate: $selectedDate, activeRange: activeRange)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Bulanan

    private var monthButton: some View {
        chrome(icon: "calendar", text: selectedDate.formattedMonthYear) {
            isShowingMonthPicker = true
        }
        .accessibilityLabel("Bulan")
        .accessibilityValue(selectedDate.formattedMonthYear)
        .popover(isPresented: $isShowingMonthPicker) {
            MonthYearPicker(selectedDate: $selectedDate)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Shared Chrome

    private func chrome(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote)

                Text(text)
                    .font(.subheadline.weight(.medium))

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.orangoTextSecondary)
            }
            .foregroundStyle(Color.orangoTextPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orangoRowBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month & Year Picker

struct MonthYearPicker: View {
    @Binding var selectedDate: Date

    @State private var month: Int
    @State private var year: Int

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let components = Calendar.current.dateComponents([.month, .year], from: selectedDate.wrappedValue)
        _month = State(initialValue: components.month ?? 1)
        _year = State(initialValue: components.year ?? 2026)
    }

    private var years: [Int] {
        let current = calendar.component(.year, from: .now)
        return Array((current - 5) ... (current + 1))
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Bulan", selection: $month) {
                ForEach(1 ... 12, id: \.self) { value in
                    Text(Self.monthNames[value - 1]).tag(value)
                }
            }
            .frame(width: 160)

            Picker("Tahun", selection: $year) {
                ForEach(years, id: \.self) { value in
                    Text(String(value)).tag(value)
                }
            }
            .frame(width: 120)
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: 300, height: 200)
        .onChange(of: month) { apply() }
        .onChange(of: year) { apply() }
    }

    /// The period runs from the 1st to the selected day, so a past month ends on its
    /// last day while the current month stops at today.
    private func apply() {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard
            let firstDay = calendar.date(from: components),
            let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count,
            let lastDay = calendar.date(byAdding: .day, value: dayCount - 1, to: firstDay)
        else { return }

        let today = calendar.startOfDay(for: .now)
        selectedDate = min(lastDay, today) >= firstDay ? min(lastDay, today) : lastDay
    }

    private static let monthNames: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "id_ID")
        return calendar.monthSymbols
    }()
}

// MARK: - Preview

#Preview {
    @Previewable @State var date = Date.now

    VStack(spacing: 16) {
        ForEach(DateFilter.allCases) { filter in
            PeriodPickerButton(
                selectedDate: $date,
                filter: filter,
                activeRange: filter.range(endingAt: date)
            )
        }
    }
    .padding()
    .background(Color.orangoPageBackground)
}
