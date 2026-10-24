# HeartPro 上架材料

2026-10-24：正式审核 build 4 因 1.4.1 引用与 5.1.1(ix) 主体要求被拒。用户决定先保持现有 TestFlight，后续再考虑组织账号。本轮只提交推送整改源码；未上传新构建、未重提正式审核、未发送回复。新源码不代表当前 TestFlight 二进制。见[整改与验证](validation/review-remediation-2026-10-24.md)、[同类经验](validation/review-experience-2026-10-24.md)及[未发送回复草稿](review-response-draft.en-US.txt)。

2026-10-11：按用户最新授权使用 **[REDACTED PERSONAL NAME] 个人团队**，运营者与版权人为 **[REDACTED PERSONAL NAME]**，品牌改为 **HeartPro**。0.6.0（3）已由 Xcode 上传、Connect 处理并选入版本；主类别为 Health & Fitness。

提审材料入口：[填写顺序](submission/README.md)。六语商店文案、审核步骤、联系人和 USD 2.99 基准价已保存。108 张原生截图已准备、复核并全部上传到 Connect（六种语言、三个设备组、每组六张）。2026-10-11 已按用户确认发布隐私标签、保存非医疗器械声明并设置 174 个地区（排除中国大陆）。实际完成范围见 [Connect 记录](evidence/connect-2026-10-10/status.json)，名称风险见 [改名记录](validation/name-review-2026-10-10.md)。

2026-10-13 当前状态：0.6.0（4）已上传并完成 Apple 处理，Internal 已加入，PB 为 Testing，正式 App Store 为 Waiting for Review；审核通过后手动发布。六语必填 iPhone/iPad 截图已更新，共 72 张；三个设备组本地素材共 108 张。USD 2.99 保留，SGD 已调整为 3.99。详见 [build 4 交付记录](evidence/build-4-2026-10-13/README.md)。

项目验证状态：独立 Watch 准确度、监管适用性、完整真机 HealthKit 与支持邮箱投递证据仍未完成。用户选择暂缓补充这些证据并推进测试和审核；保留全部分析功能与如实的限制披露，`readiness.json` 中证据门槛保持未完成。

## 已准备

- [App Store Connect 填写表](connect-settings.md)：标识、URLs、隐私问卷、年龄分级、商店/账户信息及图片规格。
- [六语商店文案](metadata/)：英、简中、日、韩、德、西；名称、副标题、描述、关键词、推广文本与首版摘要，关键词按 UTF-8 字节校验。
- [App Review 英文说明](review-notes.txt)：包含首次使用须知、无需账号的示例流程、HealthKit 读写与算法边界，如实说明准确度验证尚未完成；审核联系人单独在后台填写。
- [六语 TestFlight 材料](testflight/)：Beta App Description 与 What to Test 分开提供。
- [隐私与年龄分级填写表](submission/privacy-and-rating.zh-CN.md)：包含当前受监管医疗器械状态申报字段，未代替实际地区定性。
- [1024px 图标](icons/)：普通和深色 RGB PNG。
- [截图资料](screenshots/README.md)：当前 0.6.0 的六语 iPhone 6.3、6.9 英寸与 iPad 13 英寸截图，共 108 张，附分语言联系表、来源及完整性校验。历史 v0.3 参考图不能上传。
- [审核核对](compliance-audit.md)、[Watch 准确度验证计划](validation/watch-accuracy-protocol.md)与[真机验收表](validation/device-checklist.md)。
- [中英网站](../website/README.md)：产品、使用指南、支持、隐私政策、方法、条款及发行状态，采用 svedocs；中英政策/条款已定稿，官网已部署到 `heartpro.alkinum.com`，支持邮箱投递单独待验证。

## 本轮应用与材料同步

设置使用正式品牌图标和支持图标，移除重复邮箱行；没有未完成分析时不显示重试。窄 QRS 标签与缩放后标注偏移已修复，拥挤文字自动分行并保留实际测量范围。首次须知、最小 HealthKit 权限与本地数据保护保持有效。

108 张六语商店 PNG 和官网中英预览已从修复后源码刷新。审核备注与六语 What to Test 已补充波段标签、缩放、大字号和全屏操作；[当前验证](submission/validation.md)及[波形标签证据](evidence/wave-labels-2026-10-10/README.md)区分模拟器、生产网站和待验证项目。根目录 ZIP 是本地准备包，不会自动同步到 App Store Connect。

## 验证边界

本地材料校验通过；截图来自合成示例，真实用户健康数据未用于本轮材料。新品牌网站已部署，公开中英隐私页面已在浏览器核实；构建已上传，后台已保存的资料见状态记录；正式 App Store build 4 已提交并等待审核，PB 已可测试；支持邮箱投递仍待验证。

项目仍待完成的独立证据：独立 Watch 准确度证据、医疗法规/法律主体与地区判断、真机 HealthKit 全流程、支持邮箱投递、独立监管/主体适用性审查；联系人、价格及 Xcode 上传已完成。正式 HTTPS 政策已完成，版权不再待填；详见 `readiness.json`，不能把材料通过视为分发就绪。

```sh
rtk proxy python3 Tools/check_appstore.py
rtk proxy python3 Tools/check_appstore.py --submission
rtk proxy python3 Tools/check_appstore.py --external-testflight
rtk proxy python3 Tools/package_appstore.py --check
rtk proxy python3 Tools/package_appstore.py --zip
```

第一条核对本地材料；第二条在当前状态应失败，列出未完成的提交门槛。不要为了得到成功状态而直接修改 `readiness.json`；每项必须有真实可审阅证据。

2026-10-11 公开 Beta：外部群组 PB，构建 0.6.0（3）Waiting for Review。六语测试资料已保存，公开链接为 https://testflight.apple.com/join/qXWxxJev 。群组有已批准构建前不能加入；详情见 [TestFlight 指引](testflight-guide.zh-CN.md)。
