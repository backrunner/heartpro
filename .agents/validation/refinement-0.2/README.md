# 0.2.0 功能与界面复核

本轮使用 Xcode 27、iPhone 17 / iOS 27 模拟器。所有截图均来自明确标记的合成演示，没有用户健康数据。原始需求覆盖及未实现项见[功能核对](../../feature-audit.md)。

## 已验证

- 纯 Swift 核心 12 项通过，包含正反向 R 峰、缺口隔离、RR 成对统计、短—长重复模式、局部振幅偏离、旧笔记兼容和持续时间。
- App 第一轮 9 项中 8 项通过；失败是时间范围 Picker 没有稳定测试标识。原始结果保存在 [initial-app-summary.json](./initial-app-summary.json)，没有改写成全通过。补充控件标识后的[趋势复测](./trends-followup-summary.json)通过；9 个 App 测试用例均已有通过记录，结果来自完整运行和定向复测。
- 通过的 App 检查包括 3 项持久化测试、2 项 PDF 测试、大字号布局、深色分析页，以及完整的备忘新增／编辑／删除／隔离和双点测量流程。
- 本轮构建成功。工程仍是纯 Swift / SwiftUI / HealthKit / SwiftData，没有 Web 容器或服务端。

## 视觉复核

检查了首页、单条详情、手动测量、备忘编辑、已保存备忘、每日页、局部形态、RR 散点、深色主题与 accessibility1 字号首页／详情。

实际检查发现校准标签被波形分片截断，以及大字号缩放倍率换行；已改成两行校准单位和单行自适应倍率。[最终布局复测](./layout-followup-summary.json)通过，重新检查了浅色、深色、accessibility1 字号及 1.5× 缩放截图，确认校准单位完整、倍率保持单行。

| 页面 | 截图 |
| --- | --- |
| 首页 | [心电历史](./screenshots/01-timeline.png) |
| ECG 详情 | [左侧刻度与红色波形](./screenshots/02-ecg-detail.png) |
| 备忘 | [记录内的备忘](./screenshots/05-note-in-detail.png)、[编辑表单](./screenshots/04-note-editor.png) |
| 趋势与设置 | [年度趋势](./screenshots/07-year-trend.png)、[设置](./screenshots/08-settings.png)、[分析方法](./screenshots/09-methods.png) |
| 深色 | [首页](./screenshots/10-timeline-dark.png)、[详情](./screenshots/11-detail-dark.png)、[RR 变异性](./screenshots/13-variability-dark.png) |
| 大字号 | [首页](./screenshots/14-large-text-timeline.png)、[详情](./screenshots/15-large-text-detail.png) |

主 tab 只有心电和趋势。备忘固定在所属 ECG 详情，导航栏也提供快捷入口；详情隐藏底部 tab。波形使用 `UIColor.systemRed`，网格保持实底，固定左轴随两轴缩放同步。UI 不再包含宣传口号、背景光晕和评分圆环。

## 验证限制

- Xcode 的 `app.screenshot()` 在一次补拍中等待超过 1,000 秒；中断该次运行后，改用公开的 `XCUIScreen.main.screenshot()`，保留全部功能断言，布局复测约 40 秒通过。
- 环境负载很高，新建专用模拟器出现应用安装服务等待；该设备已关闭。中断的 Refinement1/2/3 结果不作为通过证据。实际复核使用原有 iPhone 17 模拟器。
- 模拟器结果不能证明真实 Watch 全历史读取、症状写回、所有设备性能或医学准确度。
- 大字号检查覆盖 accessibility1 的首页和详情，不等于完成所有字号、屏幕宽度和 VoiceOver 流程审核。
- 自动波段边界、经验证早搏分类、正常搏动 HRV、真实健康评分仍是实质缺口；不会用演示数据填充真实记录。


## 复现命令

```sh
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy xcodegen generate
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO test
```

对应结果包：`FinalUIReview.xcresult`（8 通过、1 标识失败）、`TrendsReview.xcresult`（标识修正后通过）、`LayoutScreenVerified.xcresult`（单位／倍率修正后通过）。中断的结果不计入通过统计，截图在有复测时以最新结果覆盖。

最后修正的年度／月份标题与「今年／本月」文案已通过[日期与设置复测](./final-dates-summary.json)，对应截图已更新。最终 App 二进制晚于全部 App 源码修改，11 份 Markdown 文档的本地链接检查通过。
