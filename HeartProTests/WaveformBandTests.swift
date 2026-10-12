import XCTest
import UIKit
@testable import HeartProCore
@testable import HeartPro

final class WaveformBandTests: XCTestCase {
    @MainActor func testNarrowQRSKeepsFullLabelAndExactTimeSpan() throws {
        let span = WaveformAnnotation(beatID: 0, kind: .qrs, start: 0.5, end: 0.58)
        let font = UIFont.systemFont(ofSize: 9, weight: .medium)
        let layout = WaveformBandLayout(annotations: [span], duration: 1, pointsPerSecond: 150, font: font)
        let entry = try XCTUnwrap(layout.entries.first)
        XCTAssertEqual(entry.band.minX, 75, accuracy: 0.001)
        XCTAssertEqual(entry.band.width, 12, accuracy: 0.001)
        XCTAssertGreaterThan(entry.label.width, entry.band.width)
        XCTAssertGreaterThanOrEqual(entry.label.width, ("QRS" as NSString).size(withAttributes: [.font: font]).width)
        // The part of the label outside the measured range remains a selection target.
        XCTAssertEqual(layout.annotation(at: CGPoint(x: entry.label.minX + 0.5, y: entry.label.midY)), span)
    }

    @MainActor func testDenseLabelsNeverOverlapAtAnyZoomOrTextSize() {
        var spans: [WaveformAnnotation] = []
        for beat in 0..<20 {
            let start = Double(beat) * 0.4
            spans.append(WaveformAnnotation(beatID: beat, kind: .p, start: start, end: start + 0.05))
            spans.append(WaveformAnnotation(beatID: beat, kind: .qrs, start: start + 0.07, end: start + 0.12))
            spans.append(WaveformAnnotation(beatID: beat, kind: .t, start: start + 0.14, end: start + 0.28))
        }
        for zoom in [0.5, 1, 1.5, 3, 6] {
            for size in [9.0, 18, 28] {
                let layout = WaveformBandLayout(annotations: spans, duration: 8, pointsPerSecond: 100 * zoom,
                                               font: .systemFont(ofSize: size, weight: .medium))
                XCTAssertEqual(layout.entries.count, spans.count)
                for (i, entry) in layout.entries.enumerated() {
                    XCTAssertEqual(layout.annotation(at: CGPoint(x: entry.label.midX, y: entry.label.midY)), entry.span)
                    XCTAssertGreaterThanOrEqual(entry.label.minX, 0)
                    XCTAssertLessThanOrEqual(entry.label.maxX, 800 * zoom)
                    XCTAssertGreaterThanOrEqual(entry.label.minY, 0)
                    XCTAssertLessThanOrEqual(entry.label.maxY, layout.height)
                    XCTAssertEqual(entry.band.minX, entry.span.start * 100 * zoom, accuracy: 0.001)
                    XCTAssertEqual(entry.band.maxX, entry.span.end * 100 * zoom, accuracy: 0.001)
                    for other in layout.entries.dropFirst(i + 1) {
                        XCTAssertFalse(entry.label.intersects(other.label), "\(zoom), \(size): \(entry.span.id) / \(other.span.id)")
                    }
                }
            }
        }
    }

    @MainActor func testClippedRangesKeepLabelsInsideContentAndEmptyInputHasNoBand() throws {
        let spans = [WaveformAnnotation(beatID: 0, kind: .qrs, start: -0.02, end: 0.01),
                     WaveformAnnotation(beatID: 1, kind: .qrs, start: 0.99, end: 1.02),
                     WaveformAnnotation(beatID: 2, kind: .qrs, start: 2, end: 3)]
        let layout = WaveformBandLayout(annotations: spans, duration: 1, pointsPerSecond: 50,
                                       font: .systemFont(ofSize: 9, weight: .medium))
        XCTAssertEqual(layout.entries.count, 2)
        XCTAssertEqual(try XCTUnwrap(layout.entries.first).band.minX, 0, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(layout.entries.last).band.maxX, 50, accuracy: 0.001)
        XCTAssertTrue(layout.entries.allSatisfy { $0.label.minX >= 0 && $0.label.maxX <= 50 })
        XCTAssertNil(layout.annotation(at: CGPoint(x: 25, y: 100)))
        XCTAssertEqual(WaveformBandLayout(annotations: [], duration: 1, pointsPerSecond: 50,
                                          font: .systemFont(ofSize: 9)).height, 0)
    }
}
