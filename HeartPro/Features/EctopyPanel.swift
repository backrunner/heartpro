import SwiftUI
import HeartProCore

struct EctopyPanel: View {
    let assessment: RhythmAssessment
    var selectTime: (Double) -> Void
    @State private var showRules = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(title: L10n.text("早搏候选与节律"))
                Spacer()
                AnalysisInfoButton(title: L10n.text("检测与评分规则")) { showRules = true }
                    .accessibilityIdentifier("rhythmRules")
            }
            AnalysisSurface {
                VStack(alignment: .leading, spacing: 16) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 24) { metrics }
                        VStack(alignment: .leading, spacing: 16) { metrics }
                    }
                    if let limitation = assessment.limitation {
                        Text(limitation.explanation).font(.caption).foregroundStyle(.secondary)
                    }
                    if !assessment.candidates.isEmpty {
                        Divider()
                        ForEach(assessment.candidates.prefix(3)) { candidateRow($0) }
                        if assessment.candidates.count > 3 {
                            DisclosureGroup(L10n.text("查看其余 \(assessment.candidates.count - 3) 次")) {
                                ForEach(assessment.candidates.dropFirst(3)) { candidateRow($0) }
                            }.font(.subheadline)
                        }
                    }
                }
            }
        }.disclosureGroupStyle(AnalysisDisclosureStyle())
            .sheet(isPresented: $showRules) {
                AnalysisHelpSheet(title: L10n.text("检测与评分规则")) {
                    Text(RhythmAssessment.caveat)
                    Text(assessment.coverageText)
                    Text(assessment.scoreBasis)
                    Text(L10n.text("分数表示未被规则标记的心跳比例，不代表健康程度。"))
                    if assessment.limitation != .sourceClassification && !assessment.flagged.isEmpty {
                        DisclosureGroup(L10n.text("可以回看的变化")) {
                            ForEach(assessment.flagged) { beat in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(L10n.text("\(beat.time, specifier: "%.2f") 秒") + " " + beat.reviewTitle).font(.subheadline.weight(.medium))
                                    Text(beat.evidence).font(.caption).foregroundStyle(.secondary)
                                }.padding(.vertical, 6)
                            }
                        }.disclosureGroupStyle(AnalysisDisclosureStyle())
                    }
                    DisclosureGroup(L10n.text("详细规则")) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(RhythmAssessment.scoreRule)
                            Text(RhythmAssessment.scoreEligibility)
                            Text(RhythmAssessment.candidateRule)
                            Text(L10n.text("宽窄分类描述波形特征，不等于已经确认心搏起源。单导联中看不清 P 波时，不推断房性或室性来源。"))
                            Text(L10n.text("规则版本：\(assessment.version)")).foregroundStyle(.secondary)
                        }.font(.caption).padding(.top, 10)
                    }.disclosureGroupStyle(AnalysisDisclosureStyle(identifier: "rhythmDetailedRules"))
                }
            }
    }
    @ViewBuilder private var metrics: some View {
        MetricValue(value: assessment.score.map(String.init) ?? "—", unit: "/ 100", label: L10n.text("节律参考分"))
            .accessibilityIdentifier("rhythmScore")
        MetricValue(value: assessment.evaluated.isEmpty || assessment.limitation == .sourceClassification ? "—" : "\(assessment.candidates.count)", unit: L10n.text("次"), label: L10n.text("早搏候选"))
    }
    private func candidateRow(_ beat: RhythmBeat) -> some View {
        Button { selectTime(beat.time) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(beat.candidate?.title ?? "").fontWeight(.medium).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text(L10n.text("\(beat.time, specifier: "%.2f") 秒")).monospacedDigit().fixedSize()
                    Image(systemName: "arrow.up.right").foregroundStyle(HP.caret)
                }.font(.subheadline)
                Text(beat.timingSummary).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }.padding(.vertical, 5).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("ectopy-\(beat.id)")
            .accessibilityLabel(beat.candidate?.title ?? "")
            .accessibilityValue(L10n.text("\(beat.time, specifier: "%.2f") 秒") + " " + beat.timingSummary)
    }
}
