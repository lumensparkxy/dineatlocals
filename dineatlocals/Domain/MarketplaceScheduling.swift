import Foundation

nonisolated var marketplaceCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = .autoupdatingCurrent
    calendar.timeZone = .autoupdatingCurrent
    return calendar
}

enum ExperienceSlotAvailability: String, Codable, Sendable {
    case available
    case blockedByHost
}

nonisolated struct DayKey: Hashable, Codable, Comparable, Identifiable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    nonisolated var id: String { storageKey }

    nonisolated var storageKey: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    nonisolated init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    nonisolated init(date: Date, calendar: Calendar = marketplaceCalendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 1970
        month = components.month ?? 1
        day = components.day ?? 1
    }

    nonisolated func date(in calendar: Calendar = marketplaceCalendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    nonisolated static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    nonisolated static func fromStorageKey(_ value: String) -> DayKey? {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        return DayKey(year: year, month: month, day: day)
    }
}

nonisolated func dayKeysBetween(
    _ startDate: Date,
    _ endDate: Date,
    calendar: Calendar = marketplaceCalendar
) -> [DayKey] {
    let start = calendar.startOfDay(for: startDate)
    let end = calendar.startOfDay(for: endDate)

    guard start <= end else { return [] }

    var days: [DayKey] = []
    var cursor = start

    while cursor <= end {
        days.append(DayKey(date: cursor, calendar: calendar))
        cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86_400)
    }

    return days
}

nonisolated func rangeDayCount(
    from startDate: Date,
    to endDate: Date,
    calendar: Calendar = marketplaceCalendar
) -> Int {
    let start = calendar.startOfDay(for: startDate)
    let end = calendar.startOfDay(for: endDate)

    guard start <= end else { return 0 }

    let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
    return difference + 1
}

nonisolated func combinedDate(
    for dayKey: DayKey,
    serviceTime: Date,
    calendar: Calendar = marketplaceCalendar
) -> Date {
    let timeComponents = calendar.dateComponents([.hour, .minute], from: serviceTime)
    let components = DateComponents(
        year: dayKey.year,
        month: dayKey.month,
        day: dayKey.day,
        hour: timeComponents.hour ?? 19,
        minute: timeComponents.minute ?? 0
    )

    return calendar.date(from: components) ?? dayKey.date(in: calendar)
}

nonisolated func materializeSlots(
    availableFrom: Date,
    availableUntil: Date,
    serviceTime: Date,
    seatCapacity: Int,
    blockedDays: Set<DayKey>,
    idFactory: ((DayKey) -> UUID)? = nil,
    calendar: Calendar = marketplaceCalendar
) -> [ExperienceSlot] {
    dayKeysBetween(availableFrom, availableUntil, calendar: calendar).map { dayKey in
        ExperienceSlot(
            id: idFactory?(dayKey) ?? UUID(),
            startAt: combinedDate(for: dayKey, serviceTime: serviceTime, calendar: calendar),
            seatCapacity: seatCapacity,
            manualAvailability: blockedDays.contains(dayKey) ? .blockedByHost : .available,
            activeSeats: 0
        )
    }
}

nonisolated func splitDayKeyCSV(_ value: String) -> Set<DayKey> {
    Set(
        value
            .split(separator: ",")
            .compactMap { DayKey.fromStorageKey(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
    )
}

nonisolated func encodeDayKeyCSV<S: Sequence>(_ values: S) -> String where S.Element == DayKey {
    Array(Set(values))
        .sorted()
        .map(\.storageKey)
        .joined(separator: ",")
}
