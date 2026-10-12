# Xcode 与 App Store Connect 操作记录

2026-10-10 按用户授权使用 [REDACTED PERSONAL NAME] 个人团队 PB8H83VL3Z。App ID 6821359492；Bundle ID com.alkinum.heartpro；SKU heartpro-ios。

## 2026-10-11 当前结果

用户最终指定桌面和公开品牌为 **HeartPro**，商店名称为 **HeartPro: ECG & HRV Diary**；其他五种语言保留 HeartPro 并使用各自的描述后缀。本次名称保存成功不代表商标清查或 Apple 审核通过。

- 0.6.0（3）在 Xcode Organizer 上传完成，Connect 处理完成、二进制状态为已验证，并已选入 App Store 版本。
- 三个设备组六种语言的 108 张截图从构建 3 源码重新捕获，并全部替换到 Connect；每种语言与设备组均核实为 6/10。
- 生产分发权限 get-task-allow=false、HealthKit=true、Team PB8H83VL3Z 已在 Connect 的构建 3 元数据中核对。
- 六语品牌文案、审核备注、App 权限文案、PDF 与官网已同步。网站部署版本为 `2fbc8e70-59e6-4dc9-90b2-4491586340b3`；中英隐私页在浏览器核实。命令行 HTTP 403 不作为验证成功。
- 本轮 18 项原生截图流程及 5 项报告测试通过。PDF 附件及实际渲染页在 `build-3-reports/`；品牌复核范围写在各截图 manifest 中。此前深色、大字号和全屏证据属于 10 月 10 日的布局验证，本轮未重复这些检查。
- 后台资料已保存，隐私标签已发布，USD 2.99、健康健美类别、174 个地区（排除中国大陆）及用户提供的审核联系人已保存；非医疗器械答复按用户声明保存。

当前证据：`connect-build-3-2026-10-11.jpg`（已验证构建）、`heartpro-version-build-3-2026-10-11.jpg`（选用构建 3）、`heartpro-large-screenshots-2026-10-11.jpg`（大屏素材）、`heartpro-name-2026-10-11.jpg`（名称）。隐私、地区截图见同目录。没有提交正式 App Store 审核；公开 TestFlight 已按下述用户新指令提交 Beta 审核。项目既有的四项独立发布证据缺口仍保留。

## 2026-10-10 操作与 2026-10-11 补充

- 品牌改为 Alkinum ECG，六语商店名称、显示名、界面、权限文案、PDF 与官网同步。名称证据见 ../../validation/name-review-2026-10-10.md。
- Xcode Archive 和 App Store Connect Distribute → Upload 完成；0.6.0（2）已处理、二进制状态已验证，并选入版本。
- Connect 实际二进制权限显示 get-task-allow=false、HealthKit=true、正确团队与 Bundle ID；没有把开发签名 archive 的权限冒充生产签名。
- 六语名称/副标题、描述/关键词/推广文本、支持/营销网址已保存；审核流程、无登录要求、用户提供的联系人、2026 [REDACTED PERSONAL NAME] 版权、16+ 年龄分级、健康健美类别和手动发布选择已保存。
- 只读核实付费/免费 App 协议有效，银行账户可用，税表使用中；未写入或接受新金融/法律条款，不在仓库记录银行标识。
- USD 2.99 美国基准价格已保存。2026-10-11 已保存当前 174 个地区，排除中国大陆，不把价格换算覆盖范围当作已启用销售范围。
- 三个设备组六语每组六张，共 108 张原生截图已上传，每批在页面核实 6/10。没有使用真实用户健康数据；截图仍显示合成示例标识。
- 隐私答案“不收集数据”和六语政策 URL 已保存；2026-10-11 用户单独授权后已发布。
- 网站部署版本 ba763fee-0bbe-4bed-baf2-ef6c628b5aec；公开中英隐私政策在浏览器核实为新品牌、个人运营者。

- 2026-10-11 已按用户明确确认保存非医疗器械声明；独立监管/主体适用性审查仍无完成证据。

## 尚未完成
- 项目既有发布门槛：独立真实 Apple Watch 准确度、真机 HealthKit 全流程与支持邮箱投递仍无完成证据。
- 未提交正式 App Store 审核、未通过 Apple 审核、未公开发布；TestFlight 构建 3 已提交 Beta 审核，公开链接已启用，等待批准后才能加入。

## 验证

本地材料检查、Connect 准备包检查、677 个键六语本地化检查、git diff --check、tracked guard 通过。网站 check、docs 检查、build 与 4 项浏览器测试通过。--submission 按真实状态失败，报告未完成门槛，没有为了得到成功结果把门槛改为完成。

status.json 记录结构化状态，不复写用户私人电话/邮箱；历史截图 connect-build-2.jpg 显示当时已验证的构建 2，privacy-publish-confirmation.jpg 保留发布前承诺画面；当前隐私标签已经用户授权发布。资料包是本地准备 ZIP，不是 IPA 或 archive，也不会自动同步后台。

2026-10-11：隐私发布证据为 privacy-published-2026-10-11.jpg，174 个地区供应证据为 availability-174-2026-10-11.jpg。资料已保存不表示 Apple 已审核通过。

## 2026-10-11 公开 TestFlight

按用户本轮明确要求，填写测试信息并推进公开 Beta，不扩展到额外验证工作。既有证据门槛未清除、未标成完成。

- 0.6.0（3）提交 Beta 审核，Connect 显示 **正在等待审核**；外部群组 **PB** 已加入此构建。
- Beta 描述、反馈邮箱、审核联系人、无需登录、营销/隐私 URL、方法和限制的审核备注已保存。Beta 描述和构建测试任务均有六种语言。
- 开启自动通知；公共链接设为向所有人开放：https://testflight.apple.com/join/qXWxxJev 。未发送额外邮件或社交平台消息。
- Connect 明确提示：群组有获准构建前，测试员不能加入公共链接。创建链接不等于 Beta 已获准或 App Store 已发布。
- 证明截图：`testflight-waiting-review-2026-10-11.jpg`、`testflight-public-link-2026-10-11.jpg`。

Apple 没有要求所有 TestFlight App 上传四份统一的准确度、监管、真机和邮箱验证证书。必要表单与实际适用审核要求见更新后的 `../../testflight-guide.zh-CN.md`；健康测量方法/准确度和医疗器械许可按功能判断，不能声称免责声明免除审核要求。用户选择暂缓新增项目验证，审核备注仍如实写明真实 Watch 独立准确度验证尚未完成。
