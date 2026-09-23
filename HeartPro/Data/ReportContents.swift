import UIKit
import HeartProCore

@MainActor enum ReportContents {
    static func render(record: ECGRecord, waveform: Waveform, notes: [JournalNote], layout: PDFReportLayout) {
        drawWaveform(waveform, record: record, layout: layout)
        if let analysis = record.analysis {
            drawSummary(analysis, record: record, layout: layout)
            if let segments = analysis.segments { drawSegments(segments, layout: layout) }
            drawMethods(analysis, record: record, layout: layout)
        }
        if !notes.isEmpty {
            layout.begin(L10n.text("记录备忘"))
            for note in notes {
                layout.section(note.date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.locale)))
                let details = [note.duration.map { L10n.text("持续 \(Int($0 / 60)) 分钟") },
                               note.symptoms.isEmpty ? nil : L10n.list(note.symptoms.map(\.title))].compactMap { $0 }
                layout.paragraph(details.joined(separator: "\n"))
                layout.paragraph(note.text, size: 10, color: PDFReportLayout.ink)
            }
        }
    }

    private static func drawWaveform(_ wave: Waveform, record: ECGRecord, layout: PDFReportLayout) {
        let mm = 72.0 / 25.4, rowHeight = 106.0, rowGap = 14.0
        let secondsPerRow = floor(layout.width / (25 * mm))
        let rows = max(1, Int(ceil(wave.duration / secondsPerRow)))
        for row in 0..<rows {
            if row == 0 || layout.y + rowHeight > layout.bottom {
                layout.begin(L10n.text("心电记录导出"))
                layout.metrics([
                    (L10n.text("心率"), "\(record.bpm?.integerText ?? "—") bpm"),
                    (L10n.text("记录时长"), L10n.text("\(record.duration.integerText) 秒")),
                    (record.isDemo ? L10n.text("合成分类") : L10n.text("Apple 分类"), record.classification.title)
                ])
                layout.paragraph("25 mm/s     10 mm/mV     " + L10n.text("按实际大小（100%）打印"), size: 8)
            }
            let start = Double(row) * secondsPerRow, end = min(wave.duration, start + secondsPerRow)
            let rect = CGRect(x: layout.margin, y: layout.y, width: layout.width, height: rowHeight)
            let cg = layout.pdf.cgContext
            cg.saveGState(); cg.clip(to: rect)
            for n in 0...Int(layout.width / mm) {
                cg.setStrokeColor(PDFReportLayout.accent.withAlphaComponent(n.isMultiple(of: 5) ? 0.18 : 0.08).cgColor)
                cg.setLineWidth(n.isMultiple(of: 5) ? 0.4 : 0.2)
                cg.move(to: CGPoint(x: rect.minX + Double(n) * mm, y: rect.minY)); cg.addLine(to: CGPoint(x: rect.minX + Double(n) * mm, y: rect.maxY)); cg.strokePath()
            }
            for n in 0...Int(rowHeight / mm) {
                cg.setStrokeColor(PDFReportLayout.accent.withAlphaComponent(n.isMultiple(of: 5) ? 0.18 : 0.08).cgColor)
                cg.setLineWidth(n.isMultiple(of: 5) ? 0.4 : 0.2)
                cg.move(to: CGPoint(x: rect.minX, y: rect.minY + Double(n) * mm)); cg.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + Double(n) * mm)); cg.strokePath()
            }
            let baseline = rect.minY + 64
            cg.setStrokeColor(UIColor(red: 0.86, green: 0.17, blue: 0.20, alpha: 1).cgColor)
            cg.setLineWidth(0.7); cg.setLineJoin(.round)
            var previous: Double?
            for point in wave.points where point.time >= start && point.time <= end {
                let p = CGPoint(x: rect.minX + (point.time - start) * 25 * mm, y: baseline - point.millivolts * 10 * mm)
                if let previous, point.time - previous <= 3 / wave.samplingFrequency { cg.addLine(to: p) } else { cg.move(to: p) }
                previous = point.time
            }
            cg.strokePath(); cg.restoreGState()
            for value in [-1.0, 0, 1, 2] {
                let y = baseline - value * 10 * mm
                if y > rect.minY + 14, y < rect.maxY - 5 {
                    layout.text(String(format: "%.0f", locale: L10n.locale, value), x: layout.margin - 18, y: y - 4, width: 14, size: 7, color: PDFReportLayout.secondary, alignment: .right)
                }
            }
            layout.text("mV", x: layout.margin - 22, y: rect.minY, width: 20, size: 7, color: PDFReportLayout.secondary)
            layout.text(L10n.text("类似 I 导联 · \(start.integerText)–\(end.integerText) 秒"), x: rect.minX + 5, y: rect.minY + 4, width: rect.width - 10, size: 7.5, color: PDFReportLayout.secondary)
            layout.y += rowHeight + rowGap
        }
    }

    private static func drawSummary(_ analysis: ECGAnalysis, record: ECGRecord, layout: PDFReportLayout) {
        layout.begin(L10n.text("分析摘要"))
        layout.metrics([
            (L10n.text("记录中的平均心率"), "\(record.bpm?.integerText ?? "—") bpm"),
            (L10n.text("信号覆盖率"), "\((analysis.qualityFraction * 100).integerText)%"),
            (L10n.text("分析时长"), L10n.text("\(analysis.validDuration.integerText) 秒"))
        ])
        layout.table(headers: [L10n.text("指标"), L10n.text("结果")], rows: [
            [L10n.text("数据来源"), record.source + (record.isDemo ? " / " + L10n.text("合成示例") : "")],
            [L10n.text("识别到的 R 波峰"), "\(analysis.peakTimes.count)"],
            [L10n.text("RR 中位数"), "\(Statistics.median(analysis.intervals.map(\.milliseconds))?.integerText ?? "—") ms"],
            [L10n.text("RR 标准差"), "\(analysis.rrSD?.integerText ?? "—") ms"],
            [L10n.text("相邻 RR 差值均方根"), "\(analysis.review?.rrRMSSD?.integerText ?? "—") ms"]
        ], widths: [230, layout.width - 230], numericFrom: 1)
        layout.paragraph(L10n.text("RR 统计未排除非窦性心搏，不作为正常心搏 HRV 指标。"))
        let hrv = ECGHRV.estimate(analysis: analysis, classification: record.classification)
        layout.section(L10n.text("本次 ECG 的 HRV"), reserve: 120)
        layout.metrics([
            ("SDNN", "\(hrv.sdnn?.integerText ?? "—") ms"),
            ("RMSSD", "\(hrv.rmssd?.integerText ?? "—") ms"),
            ("SD1 / SD2", "\(hrv.sd1?.integerText ?? "—") / \(hrv.sd2?.integerText ?? "—") ms")
        ])
        if hrv.unavailable == nil {
            layout.paragraph(L10n.text("使用 \(hrv.duration.integerText) 秒清晰信号，\(hrv.intervals.count) 个心跳间隔"))
        }
        layout.paragraph(hrv.explanation)
        if let assessment = record.rhythmAssessment {
            layout.section(L10n.text("早搏候选与节律"), reserve: 110)
            layout.metrics([
                (L10n.text("节律参考分"), assessment.score.map { "\($0) / 100" } ?? "—"),
                (L10n.text("早搏候选"), assessment.evaluated.isEmpty ? "—" : L10n.text("\(assessment.candidates.count) 次"))
            ])
            if let limitation = assessment.limitation { layout.paragraph(limitation.explanation) }
            layout.paragraph(L10n.text("共识别 \(assessment.detectedBeatCount) 个心搏，\(assessment.evaluated.count) 个纳入分析。") + "\n" +
                             L10n.text("标记 \(assessment.flagged.count) 个心搏，同一心搏不重复计数。"))
            if !assessment.flagged.isEmpty {
                layout.table(headers: [L10n.text("时间"), L10n.text("类型"), L10n.text("测量依据")],
                    rows: assessment.flagged.map { [L10n.text("\($0.time, specifier: "%.2f") 秒"), reportTitle($0), reportEvidence($0)] },
                    widths: [55, 126, layout.width - 181], continuation: L10n.text("早搏候选与节律"))
            }
            layout.paragraph(L10n.text("自动标记需结合原始波形核查。节律评分不用于评价心脏健康状况。"))
        }
        if let review = analysis.review, !review.events.isEmpty {
            let headers = [L10n.text("时间"), L10n.text("类型"), L10n.text("测量依据")]
            let rows = review.events.map { [L10n.text("\($0.time, specifier: "%.2f") 秒"), $0.kind.title, $0.displayDetail] }
            let widths = [55.0, 126, layout.width - 181]
            layout.section(L10n.text("波形事件"), reserve: min(600, layout.tableHeight(headers: headers, rows: rows, widths: widths)))
            layout.table(headers: headers, rows: rows, widths: widths, continuation: L10n.text("波形事件"))
        } else if analysis.review == nil && !analysis.outliers.isEmpty {
            layout.section(L10n.text("波形事件"))
            layout.table(headers: [L10n.text("时间"), L10n.text("RR 间期")],
                rows: analysis.outliers.map { [L10n.text("\($0.time, specifier: "%.2f") 秒"), "\($0.milliseconds.integerText) ms"] },
                widths: [180, layout.width - 180], numericFrom: 1)
        }
    }

    private static func drawSegments(_ segments: SegmentAnalysis, layout: PDFReportLayout) {
        layout.transition(to: L10n.text("心电分段分析"))
        layout.paragraph(L10n.text("范围为本次记录的最小值至最大值，不是临床参考区间。中间 80% 范围为 P10–P90。") + "\n" +
                         "— " + L10n.text("暂时无法测量"))
        if let reason = segments.displayUnavailableReason { layout.paragraph(reason) }
        for segment in segments.visibleSegments {
            let rows = segment.metrics.map { metric -> [String] in
                let s = segments.statistics(metric)
                func value(_ n: Double?) -> String { n.map { metric.format($0) + " " + metric.unit } ?? "—" }
                func range(_ low: Double?, _ high: Double?) -> String {
                    guard let low, let high else { return "—" }
                    return "\(metric.format(low))–\(metric.format(high)) \(metric.unit)"
                }
                return [metric.title, value(s.median), range(s.minimum, s.maximum), range(s.p10, s.p90), "\(s.count) / \(s.total)"]
            }
            let reasons = segments.missingReasons(segment)
            let reasonText = reasons.isEmpty ? "" : L10n.text("缺失原因") + ": " + reasons.joined(separator: "; ")
            let headers = [L10n.text("测量项目"), L10n.text("中位数"), L10n.text("范围"), "P10–P90", L10n.text("有效 / 总数")]
            let widths = [162.0, 79, 103, 103, layout.width - 447]
            let blockHeight = layout.tableHeight(headers: headers, rows: rows, widths: widths) + layout.height(reasonText, width: layout.width, size: 8) + 10
            layout.section(segment.title, reserve: min(600, blockHeight))
            layout.table(headers: headers, rows: rows, widths: widths, continuation: segment.title, numericFrom: 1)
            if !reasonText.isEmpty { layout.paragraph(reasonText, size: 8) }
            let reference = segment.adultReference
            layout.paragraph(reference.range + "\n" + reference.context, size: 8)
        }
    }

    private static func drawMethods(_ analysis: ECGAnalysis, record: ECGRecord, layout: PDFReportLayout) {
        layout.begin(L10n.text("测量方法"))
        layout.paragraph(SegmentAnalysis.method)
        layout.table(headers: [L10n.text("指标"), L10n.text("结果")], rows: [
            [L10n.text("数据来源"), record.source],
            [L10n.text("采样频率"), "\(record.samplingFrequency.integerText) Hz"],
            [L10n.text("分析版本"), analysis.version]
        ], widths: [170, layout.width - 170])
        if let assessment = record.rhythmAssessment {
            layout.section(L10n.text("检测与评分规则"))
            layout.paragraph(RhythmAssessment.scoreRule)
            layout.paragraph(RhythmAssessment.scoreEligibility)
            layout.paragraph(RhythmAssessment.candidateRule)
            layout.paragraph(L10n.text("规则版本：\(assessment.version)"), size: 8)
        }
        if let segments = analysis.segments {
            for segment in segments.visibleSegments {
                layout.section(segment.title, reserve: 50)
                layout.paragraph(segment.measurementDetails)
            }
        }
    }

    private static func reportTitle(_ beat: RhythmBeat) -> String {
        switch beat.candidate {
        case .wide: L10n.text("疑似早搏（宽 QRS）")
        case .narrow: L10n.text("疑似早搏（窄 QRS）")
        case .undetermined: L10n.text("疑似早搏（未分型）")
        case nil: beat.reviewTitle
        }
    }
    private static func reportEvidence(_ beat: RhythmBeat) -> String {
        guard let before = beat.precedingRR, let after = beat.followingRR, let reference = beat.referenceRR,
              let width = beat.qrsWidth, let correlation = beat.correlation else { return "—" }
        return L10n.text("前序 RR \(before, specifier: "%.0f") ms；参考 RR \(reference, specifier: "%.0f") ms；后续 RR \(after, specifier: "%.0f") ms。QRS 估计时限 \(width, specifier: "%.0f") ms；相关系数 \(correlation, specifier: "%.2f")。")
    }
}
