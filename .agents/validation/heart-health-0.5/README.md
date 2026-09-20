# 每日心脏健康 0.5 验证

本轮代码：统一三类读取授权；HealthKit 日常心率与 SDNN 概览/趋势；日期筛选；后台轻量分页；分段参考说明；单次 ECG HRV 与 Poincaré 图。完整规则见 [设计文档](../../heart-health-0.5.md)。

## 已通过

- `swift test --package-path Packages/HeartProCore`：42 项。包含原有检测/逐搏/多语言测试，以及新 HRV 连续片段、异常节律/质量/过短记录拒绝、候选两侧排除、不跨缺口、数值公式、参考边界、夏令时、轻量摘要测试。见 [日志](core-tests.log)。
- `Tools/localization.py --check`：602 个键、6 种语言及权限说明，占位符一致。
- iOS Simulator arm64 应用构建通过；最终代码的 arm64/x86_64 `build-for-testing` 通过，App、存储/PDF测试及UI测试均可编译。见 [应用构建](simulator-build.log)和[最终测试构建](test-build.log)。这不等于测试运行通过。

## 已添加但未得到运行结果

- App 测试：三类权限集合、轻量列表/完整详情、500天前日期直查与日边界、刷新保留分页、清空日常健康缓存；原有存储及 PDF 回归。
- UI 测试：landing 文案、历史日历筛选、左右切日与恢复全部、每日心脏健康/趋势、PR参考区间、ECG HRV图、德语大字号深色布局。
- 本轮模拟器启动/应用启动卡住，没有产生应用或界面测试的通过结果。尝试专用设备重启及新的 `HeartPro-Health05` 设备；新设备可以显示系统桌面，应用启动请求仍超时。采样显示进程停在 `dyld_sim → mapSplitCachePrivate → mmap`，尚未进入应用代码，见[进程采样](simulator-launch-sample.txt)。停止了卡住的本任务测试进程。不能将编译成功或桌面截图视为 UI 验证。见 [最后一次测试启动日志](native-attempt.log)。

## 尚未验证

- 真机 HealthKit 三类读取权限、部分授权/拒绝、原始 Watch 心率和 HRV 接入，以及持久库升级迁移。
- 真实长历史的滚动帧率、内存和长时间同步。已减少列表解码/绘制负担，不能据此报告某个帧率提升。
- ECG HRV 筛选与测量临床准确性；自动筛选不确认正常心搏。六语医学文案也尚未经专业母语审校。

## 复测

```sh
rtk proxy python3 Tools/localization.py --check
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,name=HeartPro-Health05' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never -only-testing:HeartProTests \
  -only-testing:HeartProUITests/HeartHealthUITests \
  -only-testing:HeartProUITests/HeartProUITests/testDailyTrendsAndSettings \
  CODE_SIGNING_ALLOWED=NO test
```
