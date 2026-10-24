---
title: "分析方法与限制"
description: "区分来源分类、本地估算、验证证据与医学判断。"
---

## 来源数据与原始波形
HealthKit 提供单导联原始电压序列、采样时间与 Apple 已保存的分类 [A1, A2]。HeartPro 展示来源分类，不执行 Apple 的房颤分类算法。波形视图按屏幕比例绘制来源数据，并支持手动两点测量。

## 信息性测量
HeartPro 是用于回看已有记录的信息性测量工具，不作为医疗器械使用。自动估算可能出错，不能用于诊断、治疗或判断个人健康状况。

### 自动估算
HeartPro 在本机运行确定性的 Swift 信号处理：检查信号质量，估计 R 峰和 RR 间隔，对比时序与局部形态，并估算符合条件的 P、PR、QRS、ST/J、T、QT、QTc 等波段与间隔。边界不清、时长不足、噪声或波段重叠可能导致无结果；缺失不补零。U 波仅在存在足够重复、清楚分离的候选时显示。

早搏候选结合时序与波形规则。宽窄分类不能确认室性或房性起源。提前心搏的一般概念参见美国心脏协会 [R1]。节律参考分是 HeartPro 自定义的、未被当前规则标记的心跳比例，不是已发表的医学量表、健康分、风险概率或安全保证，既可能误报也可能漏检。


HeartPro 只展示本次记录的测量值与分布，不提供成人正常区间、正常与异常比较或个人临床解释。波形与 P / PR 定义见 [E1, E2]，ST、T、U、QT 与校正方法见 [E3]。这些来源解释概念和方法，不是套用于本次记录的诊断阈值。首次使用须知可在设置中重看，但不能替代算法验证或适用的监管要求。

检测阈值、质量筛选、候选标签和节律参考分是 HeartPro 自定义的实现规则，在应用和 PDF 的方法说明中披露，不归因于医学指南。有关记录组成的文献不能验证这些规则。

## 两种不同的 HRV
Apple 健康 HRV 使用 HealthKit 提供的 SDNN 样本 [A3]。单次短 ECG 的 HRV 是独立估算：使用符合规则的间隔，相邻间隔统计不跨被剔除的缺口。筛选规则不能确认正常心搏。SDNN、RMSSD 与 Poincaré SD1/SD2 概念见 [H1]。短记录可以计算间隔统计，但可靠性取决于指标、记录时长与采集条件。Munoz 等人（2015）和 Burma 等人（2021）在不同实验条件下得到不同结论 [H2, H3]，均未验证 HeartPro 或其 Watch 实现。约 30 秒的估算不能等同标准五分钟 HRV 或混用其测量背景。

## 验证现状
自动计算尚未与独立标注的真实 Apple Watch 记录进行准确度验证。此前针对八条公开 MIT-BIH 记录的开发对照报告了 43.78% 的早搏总体检出率，复杂节律存在明显漏检。该 Holter 数据与 Watch 单导联不同，只是有限开发基准，不能视为临床准确度或代表性的 Watch 验证。

目前不宣称 HeartPro 获得医疗监管许可。保留功能不等于可以提交审核，真实 Watch 准确度证据是发行前置条件。合成信号、界面测试或 PDF 验证均不能证明医学表现。

## 医疗决定
HeartPro 无法可靠识别或排除心梗、缺血及其他心脏疾病。高分、未标记候选、缺失数值或 Apple 窦性心律分类都不能保证安全。医疗决定前请咨询医生。持续胸痛、明显气短或晕厥时，应立即寻求急救。Apple ECG 说明介绍了单导联的局限、其 ECG 应用不能检测心梗以及就医提示 [A1]，不构成对 HeartPro 分析的验证。

## 参考资料
应用和 PDF 使用相同编号。应用内「设置 → 健康信息与来源」提供完整目录，相关说明面板也直接链接来源。书目信息保留原始发表语言。

- [A1 — Apple Support：Apple Watch ECG 的使用与限制](https://support.apple.com/en-us/120278)。
- [A2 — Apple Developer：HKElectrocardiogram](https://developer.apple.com/documentation/healthkit/hkelectrocardiogram)。
- [A3 — Apple Developer：heartRateVariabilitySDNN](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn)。
- [E1 — Cascino 与 Shea：Electrocardiography，MSD 专业版，2026](https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography)。
- [E2 — Douedi 与 Douedi：P wave，StatPearls，2023 年更新](https://www.ncbi.nlm.nih.gov/books/NBK551635/)。
- [E3 — Rautaharju 等：AHA / ACCF / HRS 记录标准化声明第四部分，Circulation，2009；doi:10.1161/CIRCULATIONAHA.108.191096](https://pubmed.ncbi.nlm.nih.gov/19228821/)。
- [H1 — Shaffer 与 Ginsberg：HRV 指标与常模综述，2017；doi:10.3389/fpubh.2017.00258](https://pubmed.ncbi.nlm.nih.gov/29034226/)。
- [H2 — Munoz 等：超短记录 HRV 有效性研究，2015；doi:10.1371/journal.pone.0138921](https://pubmed.ncbi.nlm.nih.gov/26414314/)。
- [H3 — Burma 等：超短时 HRV 的有效性、可靠性与生理条件，2021；doi:10.1152/japplphysiol.00955.2020](https://pubmed.ncbi.nlm.nih.gov/33856258/)。
- [R1 — 美国心脏协会：提前心搏 PAC / PVC，2024](https://www.heart.org/en/health-topics/arrhythmia/about-arrhythmia/premature-contractions-pacs-and-pvcs)。
- [R2 — 美国心脏协会：心率与静息参考，2024](https://www.heart.org/en/health-topics/high-blood-pressure/the-facts-about-high-blood-pressure/all-about-heart-rate-pulse)。
- [仅用于开发基准 — PhysioNet：MIT-BIH 心律失常数据库](https://physionet.org/content/mitdb/1.0.0/)。

这些资料用于解释数据来源和概念，不能代替 HeartPro 自身实现的验证。
