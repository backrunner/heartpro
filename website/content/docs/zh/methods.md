---
title: "分析方法与限制"
description: "区分来源分类、本地估算、验证证据与医学判断。"
---

## 来源数据与原始波形
HealthKit 提供单导联原始电压序列、采样时间与 Apple 已保存的分类。HeartPro 展示来源分类，不执行 Apple 的房颤分类算法。波形视图按屏幕比例绘制来源数据，并支持手动两点测量。

## 自动估算
HeartPro 在本机运行确定性的 Swift 信号处理：检查信号质量，估计 R 峰和 RR 间隔，对比时序与局部形态，并估算符合条件的 P、PR、QRS、ST/J、T、QT、QTc 等波段与间隔。边界不清、时长不足、噪声或波段重叠可能导致无结果；缺失不补零。U 波仅在存在足够重复、清楚分离的候选时显示。

早搏候选结合时序与波形规则。宽窄分类不能确认室性或房性起源。节律参考分表示未被当前规则标记的心跳比例，不是健康分、风险概率或安全保证，既可能误报也可能漏检。

## 两种不同的 HRV
Apple 健康 HRV 使用 HealthKit 提供的 SDNN 样本。单次短 ECG 的 HRV 是独立估算：使用符合规则的间隔，相邻间隔统计不跨被剔除的缺口。筛选规则不能确认正常心搏，约 30 秒的估算不能等同标准五分钟 HRV 或套用其常模。

## 验证现状
自动计算尚未与独立标注的真实 Apple Watch 记录进行准确度验证。此前针对八条公开 MIT-BIH 记录的开发对照报告了 43.78% 的早搏总体检出率，复杂节律存在明显漏检。该 Holter 数据与 Watch 单导联不同，只是有限开发基准，不能视为临床准确度或代表性的 Watch 验证。

目前不宣称 HeartPro 获得医疗监管许可。保留功能不等于可以提交审核，真实 Watch 准确度证据是发行前置条件。合成信号、界面测试或 PDF 验证均不能证明医学表现。

## 医疗决定
HeartPro 无法可靠识别或排除心梗、缺血及其他心脏疾病。高分、未标记候选、缺失数值或 Apple 窦性心律分类都不能保证安全。医疗决定前请咨询医生。持续胸痛、明显气短或晕厥时，应立即寻求急救。

## 参考资料
- [Apple：使用 Apple Watch ECG](https://support.apple.com/en-us/120278)
- [Apple：HealthKit 心电数据](https://developer.apple.com/documentation/healthkit/hkelectrocardiogram)
- [Shaffer 与 Ginsberg：HRV 指标与参考值综述](https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/)
- [MSD：心电图介绍](https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography)
- [PhysioNet：MIT-BIH 心律失常数据库](https://physionet.org/content/mitdb/1.0.0/)

这些资料用于解释数据来源和概念，不能代替 HeartPro 自身实现的验证。
