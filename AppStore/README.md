# HeartPro 上架材料

提审材料入口：[按 App Store Connect 页面排列的填写顺序](submission/README.md)。当前已补齐六语商店文案、六语 TestFlight 简介/测试说明和 72 张原生截图；账号、版权、联系人、价格按用户最新要求继续待填。统一字段与截图映射见 `submission/connect-payload.json`。

2026-09-22：用户确认个人账号、外部 TestFlight、尽量多地区；保留分析功能并增加首次使用须知，移除个体病因/用药解释。请先读[本项目的 Xcode → 外部 TestFlight 指引](testflight-guide.zh-CN.md)及[本轮核对](validation/compliance-2026-09-22.md)。外部测试同样需要 Beta App Review，不能用免责声明代替主体、方法及准确度证据。

当前状态：**本地准备完成的部分可供审阅，仍有阻塞项，尚不可提交 App Store**。保留全部分析功能；按用户决定，真实 Apple Watch 准确度验证完成后再提交。

## 已准备

- [App Store Connect 填写表](connect-settings.md)：标识、URLs、隐私问卷、年龄分级、商店/账户信息及图片规格。
- [六语商店文案](metadata/)：英、简中、日、韩、德、西；名称、副标题、描述、关键词、推广文本与首版摘要，关键词按 UTF-8 字节校验。
- [App Review 英文说明](review-notes.txt)：包含首次使用须知、无需账号的示例流程、HealthKit 读写与算法边界，如实说明准确度验证尚未完成；审核联系人单独在后台填写。
- [六语 TestFlight 材料](testflight/)：Beta App Description 与 What to Test 分开提供。
- [隐私与年龄分级填写表](submission/privacy-and-rating.zh-CN.md)：包含当前受监管医疗器械状态申报字段，未代替实际地区定性。
- [1024px 图标](icons/)：普通和深色 RGB PNG。
- [截图资料](screenshots/README.md)：当前 0.6.0 的六语 iPhone 6.9 英寸与 iPad 13 英寸截图，共 72 张，附分语言联系表、来源及完整性校验。历史 v0.3 参考图不能上传。
- [审核核对](compliance-audit.md)、[Watch 准确度验证计划](validation/watch-accuracy-protocol.md)与[真机验收表](validation/device-checklist.md)。
- [中英网站](../website/README.md)：产品、使用指南、支持、隐私政策、方法、条款及发行状态，采用 svedocs；未部署，政策仍需定稿。

## 本轮应用修正

包名统一为 `com.alkinum.heartpro`；添加 UserDefaults required-reason 声明；设置增加隐私政策、支持网站/邮箱入口；清空数据同时删除临时 PDF；症状保存不再请求未使用的症状读取权限；增加“医疗决定前咨询医生”的明确提醒并提供六语文案。原有分析能力全部保留。

## 验证边界

核心测试、构建、语言检查、原生测试与网站测试结果见 [验证记录](validation/results.md)。模拟器初次启动失败后的重试已完成当前界面拍摄，网站也使用当前版本截图。未读取用户健康数据，未上传 App Store，未发送支持邮件，也未进行生产网站部署。

提交前须补齐：独立 Watch 准确度证据、医疗法规/法律主体判断、真机 HealthKit 全流程、正式 HTTPS 政策/支持页、分发签名和 App Store Connect 账户资料。用户选择暂时跳过主体、地区和邮件服务商等资料，隐私政策及条款继续保留草稿，不把缺项默认为已通过。详情见审核核对表。

```sh
rtk proxy python3 Tools/check_appstore.py
rtk proxy python3 Tools/check_appstore.py --submission
rtk proxy python3 Tools/check_appstore.py --external-testflight
rtk proxy python3 Tools/package_appstore.py --check
rtk proxy python3 Tools/package_appstore.py --zip
```

第一条核对本地材料；第二条在当前状态应失败，列出未完成的提交门槛。不要为了得到成功状态而直接修改 `readiness.json`；每项必须有真实可审阅证据。
