# 日期筛选与波形边界修复验证

2026-10-13：两项修复通过相关自动化回归及独立开发安装的真机复测。现有 TestFlight 0.6.0 (3) 保留；本次修复尚未上传 TestFlight。当前源文件、签名开发安装和截图的摘要见 [status.json](status.json)。

## 行为与实现

- 日期筛选：在 SwiftUI List 中将筛选行按钮设为 plain，使“前一天”“后一天”“全部记录”分别执行自己的动作；箭头命中区域为 44×44 pt。前后切换保留筛选，只有“全部记录”清除筛选，当天禁用后一天。
- 波形导航：半秒分片使用 HStack 的完整布局，避免缩放与旋转后离屏分片的估算位置；ScrollPosition 按 leading/trailing 边界执行开头/末尾命令。标签定位仍按原始时间选择分片；原始采样、算法、测量公式及 HealthKit 权限没有改变。
- 新增日期动作回归和波形边界回归。边界测试检查首/末分片实际在可见区域内的几何位置，不只检查请求的滚动目标。

Apple API 参考：[ScrollPosition](https://developer.apple.com/documentation/swiftui/scrollposition)。

## 自动化验证：通过

最终实现的结果包：

| 环境 | 结果 | 范围 |
| --- | --- | --- |
| iPhone 17 Pro，iOS 27.0 模拟器 | 1 通过，0 失败 | 新波形边界测试，浅色与深色大字号、0.5×/6×、两点测量、全屏与旋转往返、开头与末尾 |
| iPad Pro 13-inch (M5)，iOS 27.0 模拟器 | 7 通过，0 失败 | 新日期测试、新波形边界测试、既有标签测试、既有全屏共享状态测试，以及 3 项 WaveformBandTests |

本机原始结果包分别为 `/tmp/heartpro-nav-scrollposition.xcresult` 与 `/tmp/heartpro-nav-final-ipad.xcresult`。测试使用 `-parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO`，相关目标为 `HeartProUITests/HeartHealthUITests` 的上述四个测试及 `HeartProTests/WaveformBandTests`。结果包留在仓库外。

修复前，日期回归能复现筛选被意外清除；修复前波形回归在完成全屏/缩放后，6× 的末分片不能完整进入可见区域。首次波形试跑另有隐藏/全屏重复按钮查询问题，已修正测试查询范围；该测试工具失败不作为产品缺陷证据。最终表格只统计最终 ScrollPosition 实现的成功结果。

目视检查并保留的原生模拟器截图：

- [iPhone 浅色 0.5× 末尾](iphone-light-half-zoom-end.png)
- [iPhone 深色大字号 6× 末尾](iphone-dark-large-maximum-zoom-end.png)
- [iPad 浅色全屏 0.5× 末尾](ipad-light-fullscreen-end.png)
- [iPad 深色大字号 6× 末尾](ipad-dark-large-maximum-zoom-end.png)

## 真机验证：通过

iPhone 17 / iOS 27.0.1，使用自动签名 Debug 版本，安装与启动均成功，严格签名校验通过。独立应用为 `app.heartpro.ios` / **HeartProFix** / 0.6.0 (3)；原 TestFlight 应用 `com.alkinum.heartpro` / 0.6.0 (3) 仍在设备上。本次不修改正式显示名称和项目 Bundle ID。

应用以 `--uitesting --skip-guide --demo` 启动，正常确认使用说明后使用合成内存记录；没有读取、写入或清除个人健康记录，没有改变用户系统外观、字号及健康权限。

1. 选择当天 → 前一天：日期变为前一天，筛选栏及对应示例记录保留。
2. 后一天返回当天：日期正确，当天的后一天按钮禁用；“全部记录”清除筛选。
3. 打开示例 ECG → 0.5× → 点击 QRS 标签 → 两点测量 → 全屏横屏 → 返回竖屏 → 波形末尾：可见最后的 24–29 秒区域和记录右边界，测量结果保留。

真机镜像原始截图（合成数据，未旋转或重绘）：

- [前一天保留筛选](phone-previous-day.png)
- [标签与测量后的全屏](phone-fullscreen.png)
- [全屏返回后的波形末尾](phone-waveform-end.png)

## 范围与待验证

此前的 [TestFlight 真机问题记录](../testflight-phone-2026-10-12/README.md) 对应原发布二进制；不会因为本次开发修复而改写旧版本结果。本次验证证明上述导航行为，未验证正式分发二进制；新 TestFlight 构建上传、处理和审核仍未执行。真机浅色/大字号按用户要求保持待验证；iOS 18–26 回退、VoiceOver 实际操作及减少透明度呈现未单独复测。临床准确度、监管适用性、真实 HealthKit 流程与支持邮箱投递不属于这次两项导航修复。

工作区保留已有未提交内容，本次没有提交、推送或修改发布就绪声明。仅审阅相对于修改前快照的三份代码差异及本目录证据；`git diff --check` 通过。
