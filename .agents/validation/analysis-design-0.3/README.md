# 分析模块界面修订验证

日期：2026-09-17（America/Denver）。Xcode 27、iOS 27 模拟器、iPhone 17，使用应用合成演示数据。

## 已验证

- 构建通过。
- 5 项 UI 流程最终均通过：逐段与逐次波形导航、深色分析与 HRV 说明、大字号布局、手动测量与备忘、趋势与设置。
- 覆盖 11 个分段入口、P 波指标菜单切换、任意心跳选择、不可测原因、前后切换、完整波形定位，以及 HRV 到 Apple 健康 SDNN 趋势的导航。
- 2 项 PDF 测试通过，包含全波形、长备忘、分段测量及描述统计。
- 已逐张检查分段列表浅色／深色、大字号列表、展开测量、逐次波形和 HRV 的原生截图；箭头为随深浅色适配的次要色，指标与标题为主文本色。

## 证据

- `design-overview.jpg`：分段列表和 HRV 的深浅色截图索引。
- `20-segment-p-summary.png`、`22-segment-qtc.png`：展开分析与指标菜单。
- `12-morphology-dark.png`：波形对比展开。
- `26-segments-large-text.png`：辅助功能大字号分段列表。
- `30-segment-metric-selection.png`、`31-unmeasured-beat.png`：切换指标与未测得的心跳。
- `native-tests.log`：第一轮 3 项 UI 和 2 项 PDF 检查通过。
- `ui-regression-initial.log`：扩展为完整 5 项 UI 回归，4 项通过；新加的未测得断言把 LabeledContent 的值误当独立静态文本，导致 1 项失败。录屏确认 UI 正确展示未测得及原因，随后将断言改为检查实际原因文本。
- `ui-final-targeted.log`：修正查询后的逐段交互，以及改进截图位置后的深色分析流程，2 项均通过。最终应用代码与完整回归时一致。

## 验证范围

仅为模拟器上的 UI／导航及 PDF 回归，不代表真实 Watch 数据或临床准确度验证。iOS 18–25 材质回退、系统降低透明度设置及真机渲染本次未运行验证。
