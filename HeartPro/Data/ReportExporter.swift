import UIKit
import HeartProCore

@MainActor enum ReportExporter {
    static func clearLocalReports() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("HeartPro-Reports", isDirectory: true)
        if FileManager.default.fileExists(atPath: root.path) { try FileManager.default.removeItem(at: root) }
    }

    static func cleanExpiredReports() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("HeartPro-Reports", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        for url in files {
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            if modified < Date.now.addingTimeInterval(-86_400) { try? FileManager.default.removeItem(at: url) }
        }
    }
    static func make(record: ECGRecord, waveform: Waveform, notes: [JournalNote]) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: PDFReportLayout.page)
        let data = renderer.pdfData { pdf in
            ReportContents.render(record: record, waveform: waveform, notes: notes,
                                  layout: PDFReportLayout(pdf: pdf, record: record))
        }
        var root = FileManager.default.temporaryDirectory.appendingPathComponent("HeartPro-Reports", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        var values = URLResourceValues(); values.isExcludedFromBackup = true; try root.setResourceValues(values)
        let url = root.appendingPathComponent("HeartPro-\(record.id.uuidString.prefix(8)).pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

}
