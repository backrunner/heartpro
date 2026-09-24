import Foundation

/// The selected unit is the aggregation grain, not the length of the chart.
public enum HeartHealthTrendRange: String, CaseIterable, Sendable {
    case day, week, month

    public var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }

    public var bucketCount: Int {
        switch self {
        case .day: 14
        case .week: 13
        case .month: 12
        }
    }

    /// Includes the selected calendar bucket; the upper bound is exclusive.
    public func interval(endingAt date: Date, calendar: Calendar = .current) -> DateInterval {
        guard let last = calendar.dateInterval(of: component, for: date),
              let start = calendar.date(byAdding: component, value: 1 - bucketCount, to: last.start) else {
            return DateInterval(start: date, end: date)
        }
        return DateInterval(start: start, end: last.end)
    }

    /// Page by one complete chart window, clamping the last page to the present.
    public func shiftedDate(from date: Date, direction: Int, now: Date = .now,
                            calendar: Calendar = .current) -> Date {
        guard let next = calendar.date(byAdding: component, value: direction * bucketCount, to: date) else { return date }
        return min(next, now)
    }

    public func points(samples: [(date: Date, value: Double)], in interval: DateInterval,
                       calendar: Calendar = .current) -> [HeartHealthTrendPoint] {
        let valid = samples.filter { $0.date >= interval.start && $0.date < interval.end && $0.value.isFinite && $0.value > 0 }
        let grouped = Dictionary(grouping: valid) {
            calendar.dateInterval(of: component, for: $0.date)?.start ?? $0.date
        }
        var cursor = interval.start
        var result: [HeartHealthTrendPoint] = []
        var segment = 0
        while cursor < interval.end {
            guard let end = calendar.date(byAdding: component, value: 1, to: cursor), end > cursor else { break }
            let values = grouped[cursor]?.map(\.value) ?? []
            if let median = Statistics.median(values) {
                result.append(HeartHealthTrendPoint(date: cursor, end: end, value: median,
                                                    count: values.count, segment: segment))
            } else {
                // Missing calendar buckets break the line instead of becoming zeroes.
                segment += 1
            }
            cursor = end
        }
        return result
    }
}

public struct HeartHealthTrendPoint: Identifiable, Sendable, Equatable {
    public var date: Date
    public var end: Date
    public var value: Double
    public var count: Int
    public var segment: Int
    public var id: Date { date }
}
