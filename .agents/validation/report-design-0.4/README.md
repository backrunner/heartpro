# 导出报告与圆形控件 — 2026-09-18

后续已按用户要求统一为应用珊瑚红主题；[当前报告与验证](../report-theme-0.4/README.md)。本目录保留当时的排版记录。

报告采用 A4 白底、深色文字、青绿色标题和浅色表头。完整原始心电图在最前，随后是分析摘要、事件、分段测量、方法及用户备忘。测量值按列对齐，单位明确；同一波段的表格与缺失原因尽量同页，跨页表格重复表头。保留全记录、全部已支持指标、逐搏依据和长备忘，不以缩短内容换取页数。

摘要使用「疑似早搏（宽／窄 QRS）」「前序 RR」「QRS 估计时限」等测量用语。重复解释收进方法页，数值页只保留必要限定。新增 28 个语言键覆盖六种语言，目前 543 个键及占位符检查通过。未改动检测算法、评分规则或研究能力边界。

信息按钮和逐搏前后切换使用 44×44 pt 圆形。iOS 26+ 使用圆形 Liquid Glass，降低透明度时使用实色背景，旧版本回退系统材质。

## 可查看的产物

- [中文报告（含疑似早搏与 U 波测试数据）](rhythm-candidates-and-u.pdf)
- [报告总览](report-overview.png)、[完整波形页](report-waveform.png)、[分析摘要](report-summary.png)、[分段测量](report-measurements.png)
- [德语测量页](report-de-measurements.png)
- [浅色圆形信息按钮](premature-candidates.png)、[德语大字号](de-large-premature-candidates.png)、[深色信息按钮](12-morphology-dark.png)
- 六语报告：[中文](report-zh-Hans.pdf)、[英语](report-en.pdf)、[日语](report-ja.pdf)、[韩语](report-ko.pdf)、[德语](report-de.pdf)、[西班牙语](report-es.pdf)
- [60 秒波形及长备忘](synthetic-long-report.pdf)

## 验证

环境：Xcode 27、iOS 27、iPhone 17 模拟器。全部附件使用合成测试数据，部分测试记录沿用 Apple Watch 来源名称。

- 4 项 `ReportTests` 通过：统计与时长、六语与文件权限、实际候选／条件 U 波、完整波形与长备忘。六语 30 秒报告逐条检测五条红色心电带；60 秒报告检测前两页五条和四条心电带，以及末尾时间和备忘结尾。
- 2 项 `RhythmUITests` 通过：中文交互和德语大字号；增加信息按钮宽高相等、至少 44 pt 的断言。日志：[报告与圆形控件](report-and-circular-controls-tests.log)。
- 分页调整后重新通过全部 4 项报告测试和 `testDarkWelcomeAndAnalysisPanels`。日志：[最终分页与深色界面](pagination-and-dark-tests.log)。
- 英文 RR 限定调整为“未排除非窦性心搏”后，六语报告用例再次通过。日志：[六语最终复测](localization-report-tests.log)。
- 人工查看最终中文报告总览、摘要、波形、德语测量页与深色信息按钮。QRS 表格完整留在一页，数值和单位没有重叠；中文含疑似早搏／U 波样例共 7 页。渲染记录：[PDF 页面清单](render-review.log)。

未进行实际打印比例核对、iOS 18 回退界面或真机 HealthKit 验证。自动化渲染检查不代表临床准确性验证。

结果包：`/tmp/heartpro-report-design-1.xcresult`、`/tmp/heartpro-report-design-final.xcresult`、`/tmp/heartpro-report-design-english.xcresult`。
