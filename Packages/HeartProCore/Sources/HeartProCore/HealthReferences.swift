import Foundation

/// Stable citation identifiers shared by the app, its explanations and exported reports.
/// Bibliographic titles retain the language of the original publication.
public enum HealthReference: String, CaseIterable, Sendable, Identifiable {
    case appleECG = "A1", healthKitECG = "A2", healthKitHRV = "A3"
    case ecg = "E1", pWave = "E2", qt = "E3"
    case hrv = "H1", shortHRV = "H2", hrvReliability = "H3"
    case prematureBeats = "R1", heartRate = "R2"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .appleECG: L10n.text("Apple：心电图的使用与限制")
        case .healthKitECG: L10n.text("Apple：HealthKit 心电数据")
        case .healthKitHRV: L10n.text("Apple：健康中的 SDNN")
        case .ecg: L10n.text("MSD：波形与间期定义")
        case .pWave: L10n.text("StatPearls：P 波与 PR 间期")
        case .qt: L10n.text("AHA / ACCF / HRS：ST、T、U 与 QT")
        case .hrv: L10n.text("HRV 指标、聚集图与测量背景")
        case .shortHRV: L10n.text("超短时 HRV：2015 年研究")
        case .hrvReliability: L10n.text("超短时 HRV：2021 年可靠性研究")
        case .prematureBeats: L10n.text("AHA：提前出现的心搏")
        case .heartRate: L10n.text("AHA：心率与影响因素")
        }
    }
    public var citation: String {
        switch self {
        case .appleECG: "Apple Support. Take an ECG with the ECG app on Apple Watch."
        case .healthKitECG: "Apple Developer. HKElectrocardiogram."
        case .healthKitHRV: "Apple Developer. heartRateVariabilitySDNN."
        case .ecg: "Cascino T, Shea MJ. Electrocardiography. MSD Manual Professional Edition. 2026."
        case .pWave: "Douedi S, Douedi H. P wave. StatPearls. Updated 2023."
        case .qt: "Rautaharju PM et al. ECG standardization, part IV. Circulation. 2009;119:e241–e250. doi:10.1161/CIRCULATIONAHA.108.191096."
        case .hrv: "Shaffer F, Ginsberg JP. An Overview of Heart Rate Variability Metrics and Norms. Front Public Health. 2017;5:258. doi:10.3389/fpubh.2017.00258."
        case .shortHRV: "Munoz ML et al. Validity of (Ultra-)Short Recordings for Heart Rate Variability Measurements. PLoS ONE. 2015;10:e0138921. doi:10.1371/journal.pone.0138921."
        case .hrvReliability: "Burma JS et al. The validity and reliability of ultra-short-term heart rate variability parameters and the influence of physiological covariates. J Appl Physiol. 2021;130:1848–1867. doi:10.1152/japplphysiol.00955.2020."
        case .prematureBeats: "American Heart Association. Premature Contractions — PACs and PVCs. 2024."
        case .heartRate: "American Heart Association. All About Heart Rate (Pulse). 2024."
        }
    }
    public var url: URL {
        let address: String
        switch self {
        case .appleECG: address = "https://support.apple.com/en-us/120278"
        case .healthKitECG: address = "https://developer.apple.com/documentation/healthkit/hkelectrocardiogram"
        case .healthKitHRV: address = "https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn"
        case .ecg: address = "https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography"
        case .pWave: address = "https://www.ncbi.nlm.nih.gov/books/NBK551635/"
        case .qt: address = "https://pubmed.ncbi.nlm.nih.gov/19228821/"
        case .hrv: address = "https://pubmed.ncbi.nlm.nih.gov/29034226/"
        case .shortHRV: address = "https://pubmed.ncbi.nlm.nih.gov/26414314/"
        case .hrvReliability: address = "https://pubmed.ncbi.nlm.nih.gov/33856258/"
        case .prematureBeats: address = "https://www.heart.org/en/health-topics/arrhythmia/about-arrhythmia/premature-contractions-pacs-and-pvcs"
        case .heartRate: address = "https://www.heart.org/en/health-topics/high-blood-pressure/the-facts-about-high-blood-pressure/all-about-heart-rate-pulse"
        }
        return URL(string: address)!
    }
    public static func markers(_ references: [Self]) -> String {
        references.map { "[\($0.rawValue)]" }.joined(separator: " ")
    }
    public static var ecgHRV: [Self] { [.hrv, .shortHRV, .hrvReliability] }
}

public enum HealthInformation {
    public static var intendedUseNotice: String {
        L10n.text("HeartPro 是用于回看已有记录的信息性测量工具，不作为医疗器械使用。自动估算可能出错，不能用于诊断、治疗或判断个人健康状况。")
    }
    public static var referenceNotice: String {
        L10n.text("这些来源解释健康概念、数据来源与计算方法，不验证 HeartPro 的算法，也不代表 Apple 或文献作者认可本应用。")
    }
    public static var implementationNotice: String {
        L10n.text("检测阈值、质量筛选、候选标签和节律参考分是 HeartPro 的自定义规则，不是医学诊断标准。")
    }
    public static var shortHRVNotice: String {
        L10n.text("短记录可以计算间隔统计，但可靠性取决于指标、记录时长和采集条件。研究结论不同，不能将本次估算等同标准五分钟 HRV。")
    }
    public static var privacySummary: String {
        L10n.text("HeartPro 不收集你的健康记录、备忘或分析结果。这些内容仅在本机处理和保存，不会自动上传至开发者或第三方服务器。没有账号、广告、跟踪或第三方分析 SDK。")
    }
    public static var privacyChoices: String {
        L10n.text("只有你主动操作时，报告才会通过系统分享功能交给所选接收方，所选症状才会写入 Apple 健康。HeartPro 不通过 iCloud 同步健康数据；Apple 健康自身的同步由系统设置管理。")
    }
}

extension ECGSegment {
    public var references: [HealthReference] {
        switch self {
        case .p, .pr, .prSegment: [.pWave, .ecg]
        case .st, .t, .qt, .qtc, .u: [.ecg, .qt]
        case .rr: [.ecg, .heartRate]
        case .qrs, .tp: [.ecg]
        }
    }
}
