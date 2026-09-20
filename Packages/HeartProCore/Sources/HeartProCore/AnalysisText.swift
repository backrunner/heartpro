import Foundation

/// Presentation copy for both new and previously saved analysis results.
/// Keep persisted values and identifiers unchanged; a wording update needs no reanalysis.
public enum AnalysisText {
    public static func readable(_ text: String) -> String {
        switch text {
        case "未检测到可供分段的 R 候选峰。":
            L10n.text("没有找到足够清楚的心跳波峰，暂时无法分段测量。")
        case "采样率低于 200 Hz，不进行精细波段定位":
            L10n.text("这条记录不够细（采样率低于 200 Hz），暂时无法准确找到波形的起止位置。")
        case "相邻 RR 超出 500–1500 ms 的研究窗口，可能出现波形重叠或峰识别错误",
             "相邻 RR 超出 350–2000 ms 的研究窗口，可能出现波形重叠或峰识别错误":
            L10n.text("这段心跳间隔超出当前算法可处理的范围，也可能是波峰识别不准。")
        case "心搏前缘／基线不完整，或跨越低质量片段和采样缺口":
            L10n.text("这次心跳附近的波形不完整，或有一段信号不清楚。")
        case "局部 TP 基线不稳定或噪声过大，无法可靠确定振幅与边界":
            L10n.text("波形的参考水平线不够稳定，或干扰较多，暂时测不清。")
        case "主峰振幅相对噪声不足":
            L10n.text("主要波峰不够突出，难以与干扰区分。")
        case "QRS 局部高频噪声过大，无法稳定定位边界":
            L10n.text("QRS 附近的波形抖动较多，暂时找不准开始和结束的位置。")
        case "QRS 起止点不清、未回到局部基线或多峰融合":
            L10n.text("QRS 的开始或结束不清楚，也可能是几个波峰连在了一起。")
        case "P 候选时限超出研究窗口，可能为噪声或波形融合":
            L10n.text("这段波形的长度超出算法可处理的范围，暂时不能确认它是 P 波。")
        case "采样点已接近或进入 T 波，不能作为 ST 电位":
            L10n.text("这个位置已接近 T 波，无法单独测量 ST。")
        case "P 波低幅、起止点不清或与相邻波形融合":
            L10n.text("P 波太小、起止位置不清，或与旁边的波形重叠。")
        case "未辨认出独立分量；不以零值代替":
            L10n.text("没有分辨出这部分波形，因此没有填写数值。")
        case "T 波低幅、边界不清、片段不完整或与下一搏重叠":
            L10n.text("T 波太小、起止位置不清，或与下一次心跳的波形重叠；记录不完整也会影响测量。")
        case "T 波起点不清，无法确定 ST 测量窗口":
            L10n.text("看不清 T 波从哪里开始，因此无法确定 ST 的测量位置。")
        case "缺少同搏 QT 与连续稳定的前序 RR":
            L10n.text("还缺少这次心跳的 QT，或附近连续、稳定的心跳间隔，暂时无法校正。")
        case "QT 终点不清，或连续 RR 不足／波动超过 10%／心率超出研究窗口":
            L10n.text("QT 的结束位置不清，或附近心跳间隔不符合校正条件。具体条件见「测量方法」。")
        case "本搏 T 终点或下一搏 P 起点不可测，或区间不连续":
            L10n.text("看不清这次 T 波的结束或下次 P 波的开始，也可能是中间有信号缺口。")
        case "前一搏缺失、P 波不清或区间不连续":
            L10n.text("缺少上一次心跳、P 波不清楚，或两次心跳之间有信号缺口。")
        case "尚无可靠的 T–U 自动分离方法":
            L10n.text("这次心跳中，没有找到与相邻波形清楚分开的 U 波候选。")
        case "U 候选未在至少三次心跳中重复出现":
            L10n.text("这个小波形没有在足够多次心跳中重复，暂不作为 U 波候选。")
        case "所需边界不可测":
            L10n.text("需要的起止位置还不够清楚，暂时无法测量。")
        case "主峰正向；Q／S 按主峰两侧的反向分量寻找":
            L10n.text("主峰朝上；Q、S 按它前后朝下的部分估计。")
        case "主峰负向；Q／R／S 命名需人工复核，未自动翻转电压":
            L10n.text("主峰朝下，保留了原来的方向；Q、R、S 的识别需要结合原图复核。")
        case "双相／多峰候选；分离的波瓣不合并为确定边界":
            L10n.text("可能同时有朝上和朝下的部分，或不止一个波峰；起止位置需要结合原图查看。")
        case "正向": L10n.text("波峰朝上")
        case "负向": L10n.text("波峰朝下")
        case "部分片段信号不足，统计仅覆盖可用区间。":
            L10n.text("有些片段的信号不够清楚，统计时已跳过。")
        case "本地节律检测尚未完成 Watch 同域验证，仅供研究参考。":
            L10n.text("这些片段通过了应用的信号检查；这不代表心电正常，也不代表每个波段都能测清。")
        default: L10n.lookup(text)
        }
    }
}

extension ECGAnalysis {
    public var displayReason: String? { reason.map(AnalysisText.readable) }
}

extension ReviewEvent.Kind {
    public var title: String {
        switch self {
        case .rr: L10n.text("这次心跳的间隔与多数不同")
        case .shortLong: L10n.text("出现一短一长的心跳间隔")
        case .repeating: L10n.text("一短一长的间隔连续出现")
        case .amplitude: L10n.text("这个波峰的大小与多数不同")
        case .shape: L10n.text("这次波形的形状与多数不同")
        }
    }
}

extension ReviewEvent {
    public var displayDetail: String {
        switch kind {
        case .rr:
            return L10n.text("两次波峰相隔 \(detail.replacingOccurrences(of: "RR ", with: ""))")
        case .shortLong:
            let intervals = detail.components(separatedBy: " ms").first ?? ""
            return L10n.text("间隔为 \(intervals) ms；与本次记录的中位数相比，前一次较短，后一次较长。")
        case .repeating:
            return L10n.text("至少连续出现了 3 组。这个变化本身不能确定是否有早搏。")
        case .amplitude:
            let storedAmplitude = detail.replacingOccurrences(of: "局部基线校正振幅 ", with: "").replacingOccurrences(of: " mV", with: "")
            let amplitude = Double(storedAmplitude).map { String(format: "%.2f mV", locale: L10n.locale, $0) } ?? storedAmplitude
            return L10n.text("相对附近参考线的波峰幅度为 \(amplitude)")
        case .shape:
            return L10n.text("R 峰附近这小段波形，与本次记录中其他心跳的典型形状不同。")
        }
    }
}
