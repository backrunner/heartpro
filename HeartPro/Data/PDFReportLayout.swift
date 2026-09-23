import UIKit
import SwiftUI
import CoreText
import HeartProCore

/// Print layout uses fixed, light colours and point sizes, independently of app appearance.
@MainActor final class PDFReportLayout {
    static let page = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    static let ink = UIColor(white: 0.16, alpha: 1)
    static let secondary = UIColor(white: 0.40, alpha: 1)
    static let accent = UIColor(HP.coral).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    static let line = accent.withAlphaComponent(0.18)
    static let tint = accent.withAlphaComponent(0.06)
    let pdf: UIGraphicsPDFRendererContext
    let record: ECGRecord
    let margin = 38.0
    let bottom = 778.0
    var width: Double { Self.page.width - margin * 2 }
    var y = 112.0
    private var title = ""
    private var pageNumber = 0

    init(pdf: UIGraphicsPDFRendererContext, record: ECGRecord) { self.pdf = pdf; self.record = record }

    func begin(_ title: String) {
        self.title = title; pageNumber += 1; pdf.beginPage()
        UIColor.white.setFill(); pdf.cgContext.fill(Self.page)
        text("HeartPro", x: margin, y: 23, width: 180, size: 11, weight: .semibold, color: Self.accent)
        text(String(record.id.uuidString.prefix(8)), x: 370, y: 25, width: 187, size: 8, color: Self.secondary, alignment: .right)
        text(title, x: margin, y: 46, width: width, size: 21, weight: .semibold)
        let dateHeight = text(record.date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.locale)),
             x: margin, y: 80, width: 230, size: 9, color: Self.secondary)
        let sourceHeight = text(record.source, x: 295, y: 80, width: 262, size: 9, color: Self.secondary, alignment: .right)
        let headerBottom = max(100, 80 + max(dateHeight, sourceHeight) + 8)
        rule(at: headerBottom)
        rule(at: 792)
        text(L10n.text("仅供记录参考，不构成医疗建议，不能替代专业医疗服务。"), x: margin, y: 803, width: 445, size: 7.5, color: Self.secondary)
        text(String(format: "%02d", pageNumber), x: 512, y: 801, width: 45, size: 9, weight: .medium, alignment: .right)
        y = headerBottom + 12
    }

    func ensure(_ height: Double) { if y + height > bottom { begin(title) } }

    func transition(to title: String) {
        self.title = title
        if y + 160 > bottom { begin(title) }
        else { section(title, reserve: 130) }
    }

    func section(_ title: String, reserve: Double = 60) {
        ensure(reserve + 28)
        text(title, x: margin, y: y + 3, width: width, size: 12, weight: .semibold, color: Self.accent)
        y += 25
    }

    func metrics(_ values: [(String, String)]) {
        let column = width / Double(values.count)
        let labelHeight = values.map { height($0.0, width: column - 22, size: 8) }.max() ?? 12
        let valueHeight = values.map { height($0.1, width: column - 22, size: 15, weight: .semibold) }.max() ?? 20
        let blockHeight = labelHeight + valueHeight + 17
        ensure(blockHeight)
        for (i, value) in values.enumerated() {
            let x = margin + Double(i) * column
            if i > 0 { rule(at: y + 2, from: x - 11, to: x - 11, endY: y + blockHeight - 13) }
            text(value.0, x: x, y: y, width: column - 22, size: 8, color: Self.secondary)
            text(value.1, x: x, y: y + labelHeight + 4, width: column - 22, size: 15, weight: .semibold)
        }
        y += blockHeight
    }

    func table(headers: [String], rows: [[String]], widths: [Double], continuation: String? = nil, numericFrom: Int? = nil) {
        let headerHeight = tableHeaderHeight(headers, widths: widths)
        func heading() {
            fill(CGRect(x: margin, y: y, width: width, height: headerHeight), color: Self.tint)
            var x = margin
            for i in headers.indices {
                text(headers[i], x: x + 8, y: y + 7, width: widths[i] - 16, size: 8, weight: .medium,
                     color: Self.secondary, alignment: numericFrom.map { i >= $0 } == true ? .right : .left)
                x += widths[i]
            }
            y += headerHeight
        }
        ensure(headerHeight + 30); heading()
        for row in rows {
            let rowHeight = tableRowHeight(row, widths: widths)
            if y + rowHeight > bottom {
                begin(title)
                if let continuation { section(continuation, reserve: headerHeight + min(rowHeight, 500)) }
                heading()
            }
            var x = margin
            for i in row.indices {
                text(row[i], x: x + 8, y: y + 6, width: widths[i] - 16, size: 9,
                     alignment: numericFrom.map { i >= $0 } == true ? .right : .left)
                x += widths[i]
            }
            y += rowHeight; rule(at: y)
        }
        y += 9
    }

    func tableHeight(headers: [String], rows: [[String]], widths: [Double]) -> Double {
        tableHeaderHeight(headers, widths: widths) + rows.reduce(0) { $0 + tableRowHeight($1, widths: widths) } + 9
    }
    private func tableHeaderHeight(_ headers: [String], widths: [Double]) -> Double {
        max(25, zip(headers, widths).map { height($0.0, width: $0.1 - 16, size: 8, weight: .medium) + 14 }.max() ?? 25)
    }
    private func tableRowHeight(_ row: [String], widths: [Double]) -> Double {
        max(24, zip(row, widths).map { height($0.0, width: $0.1 - 16, size: 9) + 12 }.max() ?? 24)
    }

    /// CoreText flows arbitrary-length notes without truncation or splitting Unicode text.
    func paragraph(_ value: String, size: Double = 9, color: UIColor = PDFReportLayout.secondary) {
        guard !value.isEmpty else { return }
        let attributed = NSAttributedString(string: value, attributes: attributes(size: size, color: color))
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        var offset = 0
        while offset < attributed.length {
            ensure(size * 3)
            let path = CGPath(rect: CGRect(x: margin, y: Self.page.height - bottom, width: width, height: bottom - y), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
            let range = CTFrameGetVisibleStringRange(frame)
            guard range.length > 0 else { begin(title); continue }
            let cg = pdf.cgContext
            cg.saveGState(); cg.textMatrix = .identity
            cg.translateBy(x: 0, y: Self.page.height); cg.scaleBy(x: 1, y: -1)
            CTFrameDraw(frame, cg); cg.restoreGState()
            let measured = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil,
                                CGSize(width: width, height: .greatestFiniteMagnitude), nil)
            offset += range.length
            y += ceil(measured.height) + 8
            if offset < attributed.length { begin(title) }
        }
    }

    @discardableResult func text(_ value: String, x: Double, y: Double, width: Double, size: Double,
                                weight: UIFont.Weight = .regular, color: UIColor = PDFReportLayout.ink,
                                alignment: NSTextAlignment = .left) -> Double {
        let attrs = attributes(size: size, weight: weight, color: color, alignment: alignment)
        let h = height(value, width: width, size: size, weight: weight)
        (value as NSString).draw(in: CGRect(x: x, y: y, width: width, height: h), withAttributes: attrs)
        return h
    }
    func height(_ value: String, width: Double, size: Double, weight: UIFont.Weight = .regular) -> Double {
        ceil((value as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes(size: size, weight: weight), context: nil).height)
    }
    func rule(at y: Double, from x: Double? = nil, to end: Double? = nil, endY: Double? = nil) {
        let cg = pdf.cgContext; cg.setStrokeColor(Self.line.cgColor); cg.setLineWidth(0.5)
        cg.move(to: CGPoint(x: x ?? margin, y: y)); cg.addLine(to: CGPoint(x: end ?? (margin + width), y: endY ?? y)); cg.strokePath()
    }
    func fill(_ rect: CGRect, color: UIColor) { pdf.cgContext.setFillColor(color.cgColor); pdf.cgContext.fill(rect) }
    private func attributes(size: Double, weight: UIFont.Weight = .regular, color: UIColor = PDFReportLayout.ink,
                            alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle(); p.lineSpacing = 2; p.alignment = alignment
        return [.font: UIFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: p]
    }
}
