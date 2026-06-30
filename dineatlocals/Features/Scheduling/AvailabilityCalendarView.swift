import SwiftUI

enum AvailabilityCalendarDayState {
    case available
    case selected
    case blocked
    case full
    case locked
    case outsideRange
}

struct AvailabilityCalendarView: View {
    let range: ClosedRange<DayKey>
    let accent: Color
    let ink: Color
    let softTint: Color
    var accessibilityRoot: String = "calendar"
    let stateForDay: (DayKey) -> AvailabilityCalendarDayState
    let canTapDay: (DayKey, AvailabilityCalendarDayState) -> Bool
    let onTapDay: (DayKey) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)

    private var sections: [CalendarMonthSection] {
        makeMonthSections(range: range)
    }

    private var weekdaySymbols: [String] {
        let calendar = marketplaceCalendar
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ink.opacity(0.58))
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.monthStart, format: .dateTime.month(.wide).year())
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ink)

                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(section.cells) { cell in
                            if let dayKey = cell.dayKey {
                                let state = stateForDay(dayKey)

                                Button {
                                    onTapDay(dayKey)
                                } label: {
                                    CalendarDayCell(
                                        dayKey: dayKey,
                                        state: state,
                                        accent: accent,
                                        ink: ink,
                                        softTint: softTint
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canTapDay(dayKey, state))
                                .accessibilityIdentifier("\(accessibilityRoot).day.\(dayKey.storageKey)")
                            } else {
                                Color.clear
                                    .frame(height: 44)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AvailabilityLegend: View {
    let accent: Color
    let ink: Color
    let softTint: Color
    let items: [(String, AvailabilityCalendarDayState)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 8) {
                    CalendarLegendSwatch(
                        state: item.1,
                        accent: accent,
                        ink: ink,
                        softTint: softTint
                    )

                    Text(item.0)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ink.opacity(0.75))
                }
            }
        }
    }
}

private struct CalendarMonthSection: Identifiable {
    let monthStart: Date
    let cells: [CalendarMonthCell]

    var id: String {
        DayKey(date: monthStart).storageKey
    }
}

private struct CalendarMonthCell: Identifiable {
    let id: String
    let dayKey: DayKey?
}

private struct CalendarDayCell: View {
    let dayKey: DayKey
    let state: AvailabilityCalendarDayState
    let accent: Color
    let ink: Color
    let softTint: Color

    var body: some View {
        VStack(spacing: 2) {
            if let systemName = symbolName {
                Image(systemName: systemName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(symbolColor)
            } else {
                Spacer()
                    .frame(height: 8)
            }

            Text("\(dayKey.day)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 7)
        .frame(height: 42)
        .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .opacity(state == .outsideRange ? 0.35 : 1)
    }

    private var background: Color {
        switch state {
        case .available:
            SupperClubPalette.paper
        case .selected:
            accent
        case .blocked:
            SupperClubPalette.paperWarm
        case .full:
            SupperClubPalette.border.opacity(0.55)
        case .locked:
            softTint
        case .outsideRange:
            SupperClubPalette.paper.opacity(0.45)
        }
    }

    private var borderColor: Color {
        switch state {
        case .selected:
            accent
        case .outsideRange:
            Color.clear
        default:
            SupperClubPalette.border
        }
    }

    private var textColor: Color {
        switch state {
        case .selected:
            .white
        case .outsideRange:
            ink.opacity(0.38)
        case .blocked, .full:
            ink.opacity(0.48)
        default:
            ink
        }
    }

    private var symbolColor: Color {
        switch state {
        case .selected:
            Color.white.opacity(0.92)
        case .locked:
            ink.opacity(0.72)
        default:
            accent.opacity(0.9)
        }
    }

    private var symbolName: String? {
        switch state {
        case .selected:
            "checkmark"
        case .blocked:
            "nosign"
        case .full:
            "person.2.slash"
        case .locked:
            "lock.fill"
        case .available, .outsideRange:
            nil
        }
    }
}

private struct CalendarLegendSwatch: View {
    let state: AvailabilityCalendarDayState
    let accent: Color
    let ink: Color
    let softTint: Color

    var body: some View {
        CalendarDayCell(
            dayKey: DayKey(year: 2026, month: 1, day: 12),
            state: state,
            accent: accent,
            ink: ink,
            softTint: softTint
        )
        .frame(width: 38, height: 38)
        .clipped()
        .allowsHitTesting(false)
    }
}

private func makeMonthSections(
    range: ClosedRange<DayKey>,
    calendar: Calendar = marketplaceCalendar
) -> [CalendarMonthSection] {
    guard let startMonth = calendar.date(from: DateComponents(year: range.lowerBound.year, month: range.lowerBound.month, day: 1)),
          let endMonth = calendar.date(from: DateComponents(year: range.upperBound.year, month: range.upperBound.month, day: 1)) else {
        return []
    }

    var sections: [CalendarMonthSection] = []
    var monthCursor = startMonth

    while monthCursor <= endMonth {
        let monthComponents = calendar.dateComponents([.year, .month], from: monthCursor)
        let year = monthComponents.year ?? 1970
        let month = monthComponents.month ?? 1
        let monthRange = calendar.range(of: .day, in: .month, for: monthCursor) ?? 1..<2
        let monthDayKey = DayKey(year: year, month: month, day: 1)
        let weekday = calendar.component(.weekday, from: monthCursor)
        let leadingPlaceholders = (weekday - calendar.firstWeekday + 7) % 7

        var cells: [CalendarMonthCell] = (0..<leadingPlaceholders).map {
            CalendarMonthCell(id: "\(monthDayKey.storageKey)-placeholder-\($0)", dayKey: nil)
        }

        for day in monthRange {
            let dayKey = DayKey(year: year, month: month, day: day)
            cells.append(CalendarMonthCell(id: dayKey.storageKey, dayKey: dayKey))
        }

        let trailingPlaceholders = (7 - (cells.count % 7)) % 7
        cells.append(contentsOf: (0..<trailingPlaceholders).map {
            CalendarMonthCell(id: "\(monthDayKey.storageKey)-trailing-\($0)", dayKey: nil)
        })

        sections.append(CalendarMonthSection(monthStart: monthCursor, cells: cells))
        monthCursor = calendar.date(byAdding: .month, value: 1, to: monthCursor) ?? monthCursor
    }

    return sections
}
