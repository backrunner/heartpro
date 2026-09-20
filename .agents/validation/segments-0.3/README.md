# 逐段分析验证 · 0.3.0

日期：2026-09-17（America/Denver）。环境：Xcode 27、Swift 6、iOS 27 模拟器，iPhone 17 类型，实例 `HeartPro-Analysis`。模拟器数据均为合成示例。

## 结果

- **24 项核心测试通过**，含 12 项新增波段测试。见 [core-tests.log](./core-tests.log)。独立分段线性夹具验证已知边界、不同采样率、极性／直流偏移、ST 正负电位、P／T 缺失、采样缺口、基线和 T 局部噪声、融合／截断、不稳定 RR、两种 QTc 公式和旧结果解码。
- 最终构建及 **6 项 App 定向测试通过**：2 项 PDF、3 项存储、1 项新增逐段导航。见 [final-app-tests.log](./final-app-tests.log)。PDF 文本检查包含全部分段标题、两种 QTc、可测数和 U 波不可测原因；完整波形及长备忘分页回归继续通过。
- 其余 4 项原有 UI 用例在本轮首个全量运行通过，涵盖浅／深色、大字号、双点测量、详情备忘、趋势与设置。该次新增导航用例失败，不能将首轮记录称为全量通过。见 [initial-app-tests.log](./initial-app-tests.log)。本轮 10 个 App 用例均取得通过结果，但最终源码只定向重跑上述 6 项。
- 导航修订将定位回调延迟到逐搏弹窗完全关闭后，最终用例确认原波形工具可点击、定位时间显示；同时验证上一／下一搏、每个分段卡片及两种 QTc 指标可访问。
- 中间两次定向运行遇到 SwiftUI 嵌套 DisclosureGroup 的标识传播，改用精确语义标签查找展开按钮与搏动行后通过。失败日志保留为 [identifier-retest.log](./identifier-retest.log)、[navigation-retest.log](./navigation-retest.log)。

## 截图

- [P 波汇总](./20-segment-p-summary.png)
- [P 波逐搏起止线、数值与原始波形](./21-segment-p-beat.png)
- [Fridericia / Bazett 汇总](./22-segment-qtc.png)
- [从逐搏详情定位到完整波形](./23-segment-locate-full-waveform.png)

已人工查看导出的 P 波、QTc 和完整波形定位截图。截图验证的是上述模拟器状态，不代表所有字号／设备／深色组合均经视觉复核。

## 复现

```sh
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,name=HeartPro-Analysis' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO test
```

最终定向运行另加 `-only-testing:HeartProTests -only-testing:HeartProUITests/HeartProUITests/testSegmentAnalysisAndBeatWaveformNavigation`。结果包在本机 `/tmp/heartpro-segment-final.xcresult`；持久化日志和截图位于本目录。

未进行真实 Watch 独立标注对照、真机 HealthKit 读写或临床准确度验证。U 波仍不可自动分离；也没有开放健康分、早搏类型或医学正常／异常判定。算法窗口、所有指标和已知限制见[逐段分析说明](../../segment-analysis.md)。
