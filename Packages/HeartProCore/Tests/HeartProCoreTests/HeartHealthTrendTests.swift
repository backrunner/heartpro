import Foundation
import Testing
@testable import HeartProCore

private func trendCalendar() throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
}

private func trendDate(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
}

@Test func dailyTrendSpansFourteenCalendarDaysAcrossDST() throws {
    let calendar = try trendCalendar()
    let anchor = try trendDate(2026, 11, 5, calendar: calendar)
    let interval = HeartHealthTrendRange.day.interval(endingAt: anchor, calendar: calendar)
    #expect(interval.start == (try trendDate(2026, 10, 23, calendar: calendar)))
    #expect(interval.end == (try trendDate(2026, 11, 6, calendar: calendar)))
    #expect(interval.duration == (14 * 24 + 1) * 3600)
    let samples = (0..<14).compactMap { day -> (Date, Double)? in
        guard let date = calendar.date(byAdding: .day, value: day, to: interval.start) else { return nil }
        return (date, Double(60 + day))
    }
    let points = HeartHealthTrendRange.day.points(samples: samples, in: interval, calendar: calendar)
    #expect(points.count == 14)
    #expect(points.last?.date == anchor)
    #expect(points.contains { $0.end.timeIntervalSince($0.date) == 25 * 3600 })
}

@Test func weeklyTrendSpansThirteenLocaleAlignedWeeks() throws {
    var calendar = try trendCalendar()
    let anchor = try trendDate(2026, 1, 1, calendar: calendar)
    let interval = HeartHealthTrendRange.week.interval(endingAt: anchor, calendar: calendar)
    #expect(interval.start == (try trendDate(2025, 10, 6, calendar: calendar)))
    #expect(interval.end == (try trendDate(2026, 1, 5, calendar: calendar)))
    let samples = (0..<91).compactMap { day -> (Date, Double)? in
        guard let date = calendar.date(byAdding: .day, value: day, to: interval.start) else { return nil }
        return (date, Double(60 + day % 7))
    }
    let points = HeartHealthTrendRange.week.points(samples: samples, in: interval, calendar: calendar)
    #expect(points.count == 13)
    #expect(points.allSatisfy { $0.value == 63 && $0.count == 7 })
    calendar.firstWeekday = 1
    let sundayInterval = HeartHealthTrendRange.week.interval(endingAt: anchor, calendar: calendar)
    #expect(calendar.component(.weekday, from: sundayInterval.start) == 1)
    #expect(calendar.component(.weekday, from: sundayInterval.end) == 1)
}

@Test func monthlyTrendIncludesTwelveMonthsAndLeapDay() throws {
    let calendar = try trendCalendar()
    let anchor = try trendDate(2024, 2, 29, calendar: calendar)
    let interval = HeartHealthTrendRange.month.interval(endingAt: anchor, calendar: calendar)
    #expect(interval.start == (try trendDate(2023, 3, 1, calendar: calendar)))
    #expect(interval.end == (try trendDate(2024, 3, 1, calendar: calendar)))
    let samples: [(Date, Double)] = (0..<12).compactMap { month -> (Date, Double)? in
        guard let date = calendar.date(byAdding: .month, value: month, to: interval.start) else { return nil }
        return (date, 70)
    } + [(anchor, 80.0)]
    let points = HeartHealthTrendRange.month.points(samples: samples, in: interval, calendar: calendar)
    #expect(points.count == 12)
    #expect(points.last?.value == 75)
    #expect(points.last?.count == 2)
}

@Test func trendAggregationExcludesOutsideSamplesAndBreaksAtMissingBuckets() throws {
    let calendar = try trendCalendar()
    for range in HeartHealthTrendRange.allCases {
        let anchor = try trendDate(2026, 9, 24, calendar: calendar)
        let interval = range.interval(endingAt: anchor, calendar: calendar)
        let third = try #require(calendar.date(byAdding: range.component, value: 2, to: interval.start))
        let samples: [(Date, Double)] = [
            (interval.start.addingTimeInterval(-1), 999), (interval.start, 60),
            (interval.start.addingTimeInterval(1), 80), (third, 90),
            (third, .nan), (third, .infinity), (third, 0), (third, -1), (interval.end, 999)
        ]
        let points = range.points(samples: samples.reversed(), in: interval, calendar: calendar)
        #expect(points.map(\.value) == [70, 90])
        #expect(points.map(\.count) == [2, 1])
        #expect(points[0].segment != points[1].segment)
        #expect(range.points(samples: [], in: interval, calendar: calendar).isEmpty)
    }
}

@Test func trendPagingHasAdjacentWindowsAndClampsToPresent() throws {
    let calendar = try trendCalendar()
    let now = try trendDate(2026, 3, 31, calendar: calendar)
    for range in HeartHealthTrendRange.allCases {
        let current = range.interval(endingAt: now, calendar: calendar)
        let previousDate = range.shiftedDate(from: now, direction: -1, now: now, calendar: calendar)
        let previous = range.interval(endingAt: previousDate, calendar: calendar)
        #expect(previous.end == current.start)
        let restoredDate = range.shiftedDate(from: previousDate, direction: 1, now: now, calendar: calendar)
        #expect(restoredDate == now)
        #expect(range.interval(endingAt: restoredDate, calendar: calendar) == current)
        #expect(range.shiftedDate(from: now, direction: 1, now: now, calendar: calendar) == now)
    }
}
