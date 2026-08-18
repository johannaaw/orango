//
//  RangeCalendarView.swift
//  OranGo
//
//  Month calendar that highlights the active period alongside the selected day.
//

import SwiftUI

struct RangeCalendarView: View {
    @Binding var selectedDate: Date
    let activeRange: DateInterval

    @State private var visibleMonth: Date = .now

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "id_ID")
        calendar.firstWeekday = 1
        return calendar
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayHeader
            monthGrid
        }
        .padding(16)
        .frame(width: 340)
        .onAppear { visibleMonth = selectedDate }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(Color.orangoTextPrimary)

            Spacer()

            Button { step(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Bulan sebelumnya")

            Button { step(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Bulan berikutnya")
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.orangoBrandOrange)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.orangoTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var monthGrid: some View {
        let days = monthDays

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let inRange = activeRange.containsDay(day, calendar: calendar)

        return Button {
            selectedDate = day
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .foregroundStyle(dayColor(isSelected: isSelected, inRange: inRange))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(dayBackground(isSelected: isSelected, inRange: inRange))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formattedIndonesian)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func dayColor(isSelected: Bool, inRange: Bool) -> Color {
        if isSelected { return .white }
        if inRange { return .orangoBrandOrange }
        return .orangoTextPrimary
    }

    @ViewBuilder
    private func dayBackground(isSelected: Bool, inRange: Bool) -> some View {
        if isSelected {
            Circle().fill(Color.orangoBrandOrange)
        } else if inRange {
            Color.orangoBrandOrange.opacity(0.14)
        }
    }

    // MARK: - Month Maths

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: visibleMonth)
    }

    /// Days of the visible month, padded with `nil` so the first day lands on its weekday.
    private var monthDays: [Date?] {
        guard
            let interval = calendar.dateInterval(of: .month, for: visibleMonth),
            let count = calendar.range(of: .day, in: .month, for: visibleMonth)?.count
        else { return [] }

        let leading = calendar.component(.weekday, from: interval.start) - calendar.firstWeekday
        let padding = [Date?](repeating: nil, count: max(0, leading))

        let days: [Date?] = (0 ..< count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
        return padding + days
    }

    private func step(by months: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            visibleMonth = calendar.date(byAdding: .month, value: months, to: visibleMonth) ?? visibleMonth
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var date = Date.now

    RangeCalendarView(
        selectedDate: $date,
        activeRange: DateFilter.weekly.range(endingAt: date)
    )
    .background(Color.orangoCardBackground)
}
