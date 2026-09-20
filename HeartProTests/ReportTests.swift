import XCTest
import PDFKit
import UIKit
import HeartProCore
@testable import HeartPro

final class ReportTests: XCTestCase {
    @MainActor func testClearLocalDataRemovesSensitiveTemporaryReports() async throws {
        let model = AppModel(container: try ECGRepository.container(inMemory: true))
        let wave = DemoData.waveform()
        let record = ECGRecord(date: .now, duration: 30, samplingFrequency: 256,
                               sampleCount: wave.points.count, appleBPM: 68, classification: .sinus, isDemo: true)
        let url = try ReportExporter.make(record: record, waveform: wave, notes: [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        await model.clearLocalData()
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        // Clearing an already empty report directory must also succeed.
        await model.clearLocalData()
        XCTAssertNil(model.errorMessage)
    }

    @MainActor func testReportContainsDescriptiveStatisticsAndDuration() throws {
        let wave = DemoData.waveform()
        let record = ECGRecord(date: .now, duration: 30, samplingFrequency: 256, sampleCount: wave.points.count, appleBPM: 68, classification: .sinus, isDemo: true, analysis: try SignalAnalyzer.analyze(wave))
        let note = JournalNote(recordID: record.id, date: .now, text: "note", duration: 120)
        let url = try ReportExporter.make(record: record, waveform: wave, notes: [note])
        defer { try? FileManager.default.removeItem(at: url) }
        let document = try XCTUnwrap(PDFDocument(url: url))
        let content = try XCTUnwrap(document.string)
        XCTAssertTrue(content.contains(ECGAnalysis.currentVersion))
        for segment in ECGSegment.supportedCases { XCTAssertTrue(content.contains(segment.title), segment.title) }
        XCTAssertTrue(content.contains("Fridericia"))
        XCTAssertTrue(content.contains("Bazett"))
        XCTAssertTrue(content.contains(L10n.text("节律参考分")))
        XCTAssertTrue(content.contains(RhythmAssessment.policyVersion))
        XCTAssertTrue(content.contains(L10n.text("暂时无法测量")))
        XCTAssertFalse(content.contains(ECGSegment.u.title))
        XCTAssertFalse(content.contains(L10n.text("暂不支持")))
        XCTAssertTrue(content.contains("RR"))
        XCTAssertTrue(content.contains(L10n.text("持续 \(2) 分钟")))
        XCTAssertGreaterThanOrEqual(document.pageCount, 3)
    }

    @MainActor func testReportsAndPermissionsInEverySupportedLanguage() throws {
        let wave = DemoData.waveform()
        let record = ECGRecord(date: .now, duration: 30, samplingFrequency: 256, sampleCount: wave.points.count,
                               appleBPM: 68, classification: .sinus, isDemo: true, analysis: try SignalAnalyzer.analyze(wave))
        let note = JournalNote(recordID: record.id, date: .now, text: "USERNOTE café 日本語 한글", symptoms: [.coffee], duration: 120)
        for language in L10n.languages {
            try L10n.withLanguage(language) {
                let url = try ReportExporter.make(record: record, waveform: wave, notes: [note])
                defer { try? FileManager.default.removeItem(at: url) }
                let pdf = try XCTUnwrap(PDFDocument(url: url))
                try assertVisibleWaveform(on: XCTUnwrap(pdf.page(at: 0)), strips: 5)
                let content = try XCTUnwrap(pdf.string)
                let compact = content.components(separatedBy: .whitespacesAndNewlines).joined()
                for segment in ECGSegment.supportedCases {
                    XCTAssertTrue(compact.contains(segment.title.components(separatedBy: .whitespacesAndNewlines).joined()), language + " " + segment.title)
                }
                XCTAssertFalse(compact.contains(ECGSegment.u.title.components(separatedBy: .whitespacesAndNewlines).joined()), language)
                XCTAssertFalse(content.contains(L10n.text("暂不支持")), language)
                XCTAssertTrue(content.contains(L10n.text("暂时无法测量")), language)
                XCTAssertTrue(compact.contains("USERNOTEcafé日本語한글"), language)
                XCTAssertFalse(content.contains("{0}"), language)
                XCTAssertTrue(compact.contains(L10n.text("早搏候选与节律").components(separatedBy: .whitespacesAndNewlines).joined()), language)
                if ["en", "de", "es", "ko"].contains(language) {
                    XCTAssertFalse(content.contains("心电"), language)
                    XCTAssertFalse(content.contains("波峰朝上"), language)
                }
                let attachment = XCTAttachment(contentsOfFile: url)
                attachment.name = "report-" + language; attachment.lifetime = .keepAlways; add(attachment)
                let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
                let bundle = try XCTUnwrap(Bundle(path: path))
                for key in ["NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"] {
                    let value = bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
                    XCTAssertNotEqual(value, key, language)
                    XCTAssertFalse(value.isEmpty, language)
                }
            }
        }
    }

    @MainActor func testReportContainsActualCandidatesAndConditionalUWave() throws {
        let wave = DemoData.rhythmExample()
        let analysis = try SignalAnalyzer.analyze(wave)
        let record = ECGRecord(date: .now, duration: wave.duration, samplingFrequency: wave.samplingFrequency,
                               sampleCount: wave.points.count, appleBPM: nil, classification: .sinus, isDemo: true, analysis: analysis)
        XCTAssertEqual(record.rhythmAssessment?.candidates.count, 2)
        XCTAssertTrue(analysis.segments?.visibleSegments.contains(.u) == true)
        let url = try ReportExporter.make(record: record, waveform: wave, notes: [])
        defer { try? FileManager.default.removeItem(at: url) }
        let content = try XCTUnwrap(PDFDocument(url: url)?.string)
        XCTAssertTrue(content.contains(L10n.text("疑似早搏（宽 QRS）")))
        XCTAssertTrue(content.contains(L10n.text("疑似早搏（窄 QRS）")))
        XCTAssertTrue(content.contains(ECGSegment.u.title))
        let attachment = XCTAttachment(contentsOfFile: url)
        attachment.name = "rhythm-candidates-and-u"; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor func testPDFIncludesFullWaveformAndLongMemo() throws {
        let wave = DemoData.waveform(seconds: 60)
        let record = ECGRecord(date: .now, duration: 60, samplingFrequency: 256, sampleCount: wave.points.count, appleBPM: 68, classification: .sinus, isDemo: true)
        let note = JournalNote(recordID: record.id, date: .now, text: String(repeating: "长备忘需要完整分页。", count: 600) + "ENDOFMEMO123456789")
        let url = try ReportExporter.make(record: record, waveform: wave, notes: [note])
        defer { try? FileManager.default.removeItem(at: url) }
        let pdf = try XCTUnwrap(PDFDocument(url: url))
        let attachment = XCTAttachment(contentsOfFile: url); attachment.name = "synthetic-long-report"; attachment.lifetime = .keepAlways; add(attachment)
        XCTAssertGreaterThanOrEqual(pdf.pageCount, 5)
        let content = try XCTUnwrap(pdf.string)
        XCTAssertTrue(content.contains("56–60") || content.contains("56〜60"), "The final ECG strip must be present")
        let unwrapped = content.components(separatedBy: .whitespacesAndNewlines).joined()
        // PDFKit may reorder underscore glyphs as separate lines; use an alphanumeric sentinel.
        XCTAssertTrue(unwrapped.contains("ENDOFMEMO123456789"), "Long notes must not be clipped. Extracted tail: \(content.suffix(100))")
        let bounds = try XCTUnwrap(pdf.page(at: 0)).bounds(for: .mediaBox)
        XCTAssertEqual(bounds.width, 595.28, accuracy: 0.1)
        for (index, strips) in [5, 4].enumerated() {
            let page = try XCTUnwrap(pdf.page(at: index))
            let preview = try assertVisibleWaveform(on: page, strips: strips)
            let image = XCTAttachment(image: preview)
            image.name = "waveform-page-\(index + 1)"; image.lifetime = .keepAlways; add(image)
        }
    }

    /// Verify rendered ECG ink, not just time labels or the pink paper grid.
    /// A missing path or a flat replacement must fail on every exported strip.
    @MainActor @discardableResult
    private func assertVisibleWaveform(on page: PDFPage, strips: Int) throws -> UIImage {
        let preview = page.thumbnail(of: CGSize(width: 1191, height: 1684), for: .mediaBox)
        let image = try XCTUnwrap(preview.cgImage)
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress, width: width, height: height,
                                                bitsPerComponent: 8, bytesPerRow: width * 4,
                                                space: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let pageSize = page.bounds(for: .mediaBox).size
        let sx = Double(width) / pageSize.width
        // Identify separated ink bands instead of coupling the check to row positions.
        var bands: [(minY: Int, maxY: Int, count: Int)] = []
        for y in 0..<height {
            var count = 0
            for x in Int(40 * sx)..<Int(535 * sx) {
                    let i = (y * width + x) * 4
                    // Isolate the darker ECG stroke from coral branding and pale grid lines.
                    if pixels[i] > 180 && pixels[i + 1] < 70 && pixels[i + 2] < 80 {
                        count += 1
                    }
            }
            if count > 0 {
                if let last = bands.last, y - last.maxY <= 12 {
                    bands[bands.count - 1].maxY = y; bands[bands.count - 1].count += count
                } else { bands.append((y, y, count)) }
            }
        }
        XCTAssertEqual(bands.count, strips, "Every waveform strip must be rendered")
        for (row, band) in bands.enumerated() {
            XCTAssertGreaterThan(band.count, 300, "ECG stroke missing from strip \(row + 1)")
            XCTAssertGreaterThan(band.maxY - band.minY, 25, "ECG strip \(row + 1) has no visible beat deflections")
        }
        return preview
    }
}
