# 使用须知设计复核

本次调整：增加品牌开场和三个分组标题，使用卡片区分专业医疗边界、分析局限和就医提醒；提高正文对比度，扩展底部按钮，在 iPad 常规宽度下居中阅读区域。原有四段说明完整保留，确认版本和健康读取顺序不变。

## 预览

- [iPhone 中文浅色](zh-usage-notice.png)
- [iPhone 中文深色](zh-iphone-dark.png)
- [iPad 中文浅色](zh-ipad-light.png)
- [六语截图总览](language-contact-sheet.jpg)：中文默认字号；英、日、韩、德、西语为 Accessibility 1 字号、深色，滚动到就医提醒。

## 验证

- 最终 Xcode 模拟器构建及现有 `UsageNoticeUITests` 两项测试通过，0 失败、0 跳过、0 运行时警告，见 [测试摘要](tests-summary.json) 和 [测试日志](tests.log)。
- 覆盖确认前不显示健康连接入口、确认后进入主界面、重启记忆确认、设置重新查看；五种外语大字号下就医提醒可完整滚动到按钮上方，按钮可操作。
- `python3 Tools/localization.py --check`：674 个键通过六语资源与占位符检查。
- `git diff --check` 通过。
- iPhone 使用 iPhone 17 Pro Max / iOS 27 模拟器；iPad 截图来自 HeartPro-AppStore-iPad 模拟器。原始测试截图映射见 [附件清单](test-attachments.json)。最终结果包为 `TestResults/UsageNoticeDesignFinal-20260922.xcresult`。

本轮是界面调整及定向验证；没有重新执行 Release 归档、真机 HealthKit 验收或上传 TestFlight。合规审核结论仍见 [合规复核记录](../../validation/compliance-2026-09-22.md)。
