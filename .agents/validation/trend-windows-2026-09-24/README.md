# 趋势窗口与整页日期切换验证

2026-09-24，当前工作区构建；全部 UI 数据来自明确标记的合成示例。

## 行为

- 趋势仅保留日／周／月，分别按日汇总近 14 天、按周汇总近 13 周、按月汇总近 12 个月。窗口包含所选时段，查询不读取今天以后的日期。
- 每日页保留小时心率范围。日期选择器固定在上方，下方完整滚动容器支持左右切换；每日页移动一天，趋势页移动一个窗口，到当前时段停止。
- 图表点按选择汇总值；横向拖动取消记录卡片的点击，不误入详情。竖向滚动和普通点按保持可用。
- 按 Calendar 计算边界，空缺不补零、不跨缺失时段连线；心率与健康 SDNN 分别聚合，不混入 ECG HRV。聚合在主线程外执行，异步结果核对日期、范围、数据 revision 和请求 generation。
- 未修改持久化 ECG 分析算法、版本或迁移格式。

## 通过

| 检查 | 结果 |
| --- | --- |
| `rtk proxy swift test --package-path Packages/HeartProCore` | 54 项通过，包含新增 5 项趋势回归：DST、跨年周与周起始日、闰年月份、非法／越界／缺失数据、相邻窗口及返回当前日期 |
| `rtk proxy python3 Tools/localization.py --check` | 675 个键、六语及占位符通过 |
| `rtk proxy xcodegen generate` | 成功，生成项目无差异 |
| iOS Simulator 构建 | Swift 6 构建和测试构建通过 |
| iPhone 17 Pro Max / iOS 27 | 3 项相关 UI 测试通过 |
| iPad Pro 13-inch (M5) / iOS 27 | 相同 3 项 UI 测试通过，其中两项在适配浮动标签栏的测试定位后重跑 |
| 目视检查 | 已打开当前构建截图：中文浅色日／月趋势、每日记录切换、空 SDNN；德语深色大字号周趋势；iPhone 和 iPad 日期范围、图表及长译文布局 |
| Git 卫生 | `rtk git diff --check` 通过，`rtk proxy git ls-files -ci --exclude-standard` 无已跟踪忽略产物 |

UI 测试：

- `HeartHealthUITests/testWholeDailyContentSwipesAndVerticalScrolling`
- `HeartHealthUITests/testTrendWindowsChartSwipesSelectionAndEmptyContent`
- `HeartHealthUITests/testLargeGermanHistoryAndDailyHealth`

测试覆盖三档数据点数量、图表滑动、日期箭头与滑动往返一致、当前日期上限、空状态和卡片外空白区域、竖向滚动、记录卡片滑动不导航及普通点按仍进入详情。

本地结果包（受 `.gitignore` 排除，不提交）：

- `TestResults/TrendPaging-iPhone-final.xcresult`：3 项通过。
- `TestResults/TrendPaging-iPad-final.xcresult`：德语大字号测试通过；另两项因 iPad 没有 `TabBar` 类型的可访问节点而失败，不作为这两项的通过证据。
- `TestResults/TrendPaging-iPad-final-v2.xcresult`：修正测试定位后，另两项通过；应用代码与上述最终构建一致。

复现 iPhone 检查；iPad 使用目的地 `73662148-35B6-4922-BE32-46C415BE1979`：

```sh
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,id=2981271F-5537-421E-BD70-0A415F6BC577' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO \
  -only-testing:HeartProUITests/HeartHealthUITests/testWholeDailyContentSwipesAndVerticalScrolling \
  -only-testing:HeartProUITests/HeartHealthUITests/testTrendWindowsChartSwipesSelectionAndEmptyContent \
  -only-testing:HeartProUITests/HeartHealthUITests/testLargeGermanHistoryAndDailyHealth test
```

## 待验证／不适用

- 待验证：物理设备手感、真实 HealthKit 长期数据、iOS 18–26 运行时、VoiceOver 实际操作和减少透明度设置。现有模拟器没有旧系统运行时；已保留 44 pt 日期按钮、可访问标签和命名操作。
- 不适用：PDF／网站／发布门槛；本次没有相关修改或分发操作。

## 同日后续：心率与 SDNN 平铺

日常心率与 Apple 健康 SDNN 改为上下两个区域，移除指标切换按钮。共用日期与汇总粒度，各自保存图表选中点。ECG 详情的 SDNN 入口自动滚到 SDNN 区域。

- 通过：应用及 UI 测试构建、675 键六语检查、`git diff --check`。
- 通过：iPhone 的趋势窗口／两区域滑动、SDNN 入口定位、德语深色大字号三项 UI 测试，见 `TestResults/FlatTrends-iPhone.xcresult`。
- 通过：iPad 的 SDNN 入口及德语深色大字号测试，见 `TestResults/FlatTrends-iPad.xcresult`；趋势滑动专项见 `TestResults/FlatTrends-iPad-v2.xcresult`。首轮滑动只跨过窄文本，调整测试为完整的横向拖动后通过，应用代码未变。
- 通过：已目视检查两设备的中文平铺、SDNN 定位、德语深色大字号截图；长正文可滚动，日期栏保持固定。
- 待验证：真机、旧系统及真实 SDNN 数据曲线；合成示例未添加虚构的健康 SDNN，本轮该区域验证了独立空状态。核心聚合未改动，沿用前述 54 项通过证据。
