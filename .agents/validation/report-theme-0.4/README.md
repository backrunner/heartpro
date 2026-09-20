# 报告主题色修正 — 2026-09-18

报告直接复用应用的 `HP.coral` 珊瑚红，替换上一版独立的青绿色。品牌和分节标题使用主题色；表头底色、分隔线与心电网格使用不同透明度的同色系。正文、数值和辅助文字改为中性灰。白底打印样式固定使用浅色主题，不随 App 深色外观改变。

本轮只调整颜色，不改内容、布局或分析算法。人工查看了导出 PDF 的波形页和摘要页；没有进行实际打印核对。

- [完整报告（合成测试数据）](rhythm-candidates-and-u.pdf)
- [摘要预览](report-summary.png)、[心电图](report-waveform.png)、[分段测量](report-measurements.png)
- 4 项 `ReportTests` 全部通过，包括六语内容、完整波形渲染和长备忘。波形像素检查区分较深的曲线与新增的珊瑚红品牌文字。见[测试日志](report-tests.log)。
- 六语文件：[中文](report-zh-Hans.pdf)、[英语](report-en.pdf)、[日语](report-ja.pdf)、[韩语](report-ko.pdf)、[德语](report-de.pdf)、[西班牙语](report-es.pdf)。

环境：Xcode 27、iOS 27、iPhone 17 模拟器。结果包：`/tmp/heartpro-report-coral.xcresult`。
