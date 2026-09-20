import SwiftUI
import Charts
import HeartProCore

struct RRVariabilityPanel: View {
    var analysis: ECGAnalysis?
    var classification: SourceClassification = .unknown
    @State private var showHelp = false
    private var estimate: ECGHRV { ECGHRV.estimate(analysis: analysis, classification: classification) }
    var body: some View {
        let result = estimate
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(title: L10n.text("本次 ECG 的 HRV"), subtitle: L10n.text("\((analysis?.duration ?? 30).integerText) 秒估算"))
                Spacer()
                AnalysisInfoButton(title: L10n.text("了解心跳间隔与 HRV")) { showHelp = true }
                    .accessibilityIdentifier("hrvHelp")
            }
            AnalysisSurface {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        MetricValue(value: result.sdnn?.integerText ?? "—", unit: "ms", label: "SDNN")
                        MetricValue(value: result.rmssd?.integerText ?? "—", unit: "ms", label: "RMSSD")
                    }
                    if !result.pairs.isEmpty {
                        Text(L10n.text("Poincaré 聚集图")).font(.subheadline.weight(.semibold))
                        let bounds = domain(result.pairs)
                        Chart {
                            ForEach(result.pairs) { pair in
                                PointMark(x: .value("RR n", pair.first), y: .value("RR n+1", pair.second))
                                    .foregroundStyle(HP.teal.opacity(0.55)).symbolSize(38)
                            }
                            ForEach(ellipse(result), id: \.id) { point in
                                LineMark(x: .value("RR n", point.first), y: .value("RR n+1", point.second), series: .value("Guide", "spread"))
                                    .foregroundStyle(HP.teal.opacity(0.7)).lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                            }
                            ForEach([bounds.lowerBound, bounds.upperBound], id: \.self) { value in
                                LineMark(x: .value("RR n", value), y: .value("RR n+1", value), series: .value("Guide", "identity"))
                                    .foregroundStyle(.secondary.opacity(0.4)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            }
                        }.chartXScale(domain: bounds).chartYScale(domain: bounds).chartLegend(.hidden)
                            .chartPlotStyle { $0.aspectRatio(1, contentMode: .fit) }
                            .chartXAxisLabel(L10n.text("前一次间隔（ms）")).chartYAxisLabel(L10n.text("后一次间隔（ms）"))
                            .frame(maxWidth: 420).aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity, alignment: .center).accessibilityIdentifier("ecgHRVPlot")
                            .accessibilityLabel(L10n.text("相邻 RR 散点图"))
                        DisclosureGroup(L10n.text("更多指标")) {
                            HStack {
                                MetricValue(value: result.sd1?.integerText ?? "—", unit: "ms", label: "SD1")
                                MetricValue(value: result.sd2?.integerText ?? "—", unit: "ms", label: "SD2")
                            }
                        }.disclosureGroupStyle(AnalysisDisclosureStyle())
                    }
                    if result.unavailable != nil { Text(result.explanation).font(.caption).foregroundStyle(.secondary) }
                    Divider()
                    NavigationLink { InsightsView(initialSection: 1, showHRV: true) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.text("Apple 健康 HRV")).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                                Text(L10n.text("查看 SDNN 趋势")).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(); CardNavigationIndicator()
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("healthHRV")
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            AnalysisHelpSheet(title: L10n.text("本次 ECG 的 HRV")) {
                Text(estimate.explanation)
                if estimate.unavailable == nil {
                    Text(L10n.text("使用 \(estimate.duration.integerText) 秒清晰信号，\(estimate.intervals.count) 个心跳间隔"))
                }
                Text(L10n.text("SDNN 描述间隔的总体分散程度；RMSSD 描述相邻间隔的变化。SD1 和 SD2 分别表示聚集图横跨和沿着对角线的分散程度。"))
                Text(L10n.text("30 秒心电也能估算 HRV。排除干扰和有变化的心跳后，SDNN 使用本次保留的全部间隔；RMSSD 和聚集图只使用原本相邻的间隔，不跨空缺连接。"))
                Text(L10n.text("每个点连接前后两次心跳间隔；点越集中，间隔越相近。虚线椭圆表示一个标准差的分布，不是正常范围。"))
                Text(L10n.text("超短时 HRV 没有统一正常区间。呼吸、姿势、睡眠和压力都会影响数值，建议在相似条件下比较。"))
                Text(L10n.text("筛选规则不能确认正常心跳，也可能漏检不规则节律；这些结果是研究性估算，不能用于诊断或与标准五分钟 HRV 等同。"))
                Text(L10n.text("Apple 健康中的 HRV 使用 SDNN。你可以单独查看它的趋势；它与本次心电的计算来源不同。"))
                Link(L10n.text("HRV 指标与参考值综述"), destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/")!)
            }
        }
    }
    private func domain(_ pairs: [SuccessiveRR]) -> ClosedRange<Double> {
        let values = pairs.flatMap { [$0.first, $0.second] }
        let low = values.min() ?? 0, high = values.max() ?? 100
        let padding = max(20, (high - low) * 0.2)
        return max(0, low - padding)...max(low + 2 * padding, high + padding)
    }
    private func ellipse(_ result: ECGHRV) -> [SuccessiveRR] {
        guard !result.pairs.isEmpty, let sd1 = result.sd1, let sd2 = result.sd2 else { return [] }
        let x = result.pairs.map(\.first).reduce(0, +) / Double(result.pairs.count)
        let y = result.pairs.map(\.second).reduce(0, +) / Double(result.pairs.count)
        return (0...64).map { index in
            let angle = Double(index) / 64 * 2 * Double.pi
            let along = sd2 * cos(angle), across = sd1 * sin(angle)
            return SuccessiveRR(id: index, first: x + (along - across) / sqrt(2), second: y + (along + across) / sqrt(2))
        }
    }
}

struct MorphologyPanel: View {
    var review: RhythmReview
    @State private var showHelp = false
    var body: some View {
        AnalysisSurface(padding: 0) {
            DisclosureGroup {
                Surface(padding: 16) {
                    VStack(alignment: .leading, spacing: 18) {
                        if review.beats.isEmpty {
                            Text(L10n.text("需要至少 12 次波形清楚、完整的心跳，才能画出对比用的参考波形。"))
                                .font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                MetricValue(value: String(format: "%.2f", locale: L10n.locale, Statistics.median(review.beats.map(\.amplitude)) ?? 0), unit: "mV", label: L10n.text("R 波幅度中位数"))
                                MetricValue(value: "\(review.beats.count)", unit: L10n.text("次"), label: L10n.text("参与对比的心跳"))
                            }
                            Chart(review.beats) { beat in
                                PointMark(x: .value(L10n.text("时间"), beat.time), y: .value(L10n.text("振幅"), beat.amplitude))
                                    .foregroundStyle(HP.ecg).symbolSize(18)
                            }.frame(height: 130).chartXAxisLabel(L10n.text("时间（秒）")).chartYAxisLabel("mV")
                            HStack {
                                Text(L10n.text("本次记录的典型波形")).font(.subheadline.weight(.medium))
                                Spacer()
                                AnalysisInfoButton(title: L10n.text("了解波形对比")) { showHelp = true }
                            }
                            Chart(review.template, id: \.time) { point in
                                LineMark(x: .value(L10n.text("相对 R 峰"), point.time * 1000), y: .value(L10n.text("电压"), point.millivolts))
                                    .foregroundStyle(HP.ecg).lineStyle(StrokeStyle(lineWidth: 1.5))
                            }.frame(height: 130).chartXAxisLabel(L10n.text("相对 R 峰（ms）")).chartYAxisLabel("mV")
                            Text(L10n.text("仅对比 R 峰附近，不代表完整心跳。"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("心跳波形对比")).font(.subheadline.weight(.semibold))
                    Text(L10n.text("查看 R 波幅度与典型波形")).font(.caption).foregroundStyle(.secondary)
                }
            }.disclosureGroupStyle(AnalysisDisclosureStyle(identifier: "morphologyPanel", inset: 18))
        }
        .sheet(isPresented: $showHelp) {
            AnalysisHelpSheet(title: L10n.text("心跳波形对比")) {
                Text(L10n.text("把每次心跳的 R 峰对齐，就可以比较附近波形的高度和形状。参考波形取各位置的中位数，帮助你看清这条记录的典型形状。"))
                Text(L10n.text("对比范围是 R 峰前 120 ms 到后 160 ms，不包含完整的 P、T 波，也不是 QRS 持续时间的测量。"))
                Text(L10n.text("接触和姿势变化也可能改变波形。波形相似或不同，都不能单独用来判断心电是否正常。"))
            }
        }
    }
}
