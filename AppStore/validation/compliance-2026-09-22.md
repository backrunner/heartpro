# HeartPro 合规复核与外部 TestFlight 准备

核对日：2026-09-22（America/New_York；部分工具日志为次日 +0800）。本次用户确认：个人开发者账号、希望尽量多地区、支持外部 TestFlight；保留记录及分析能力，通过独立首次使用说明明确能力边界。

**结论：代码和材料可继续准备，尚不能宣称全面合规或外部测试审核就绪。** 本次没有签名上传、提交 Beta App Review、公开邀请测试者、发布网站或发送邮件。

## 已完成的产品修改

- 首次使用先显示独立的六语「使用须知」。说明数值、候选、参考值及评分不构成医疗建议，不能替代医生、诊断、治疗或医疗服务；不能据此自行改变用药或延误就医；身体不适及时就医，紧急症状联系当地急救服务。
- 确认后才启动本地记录加载、健康同步和使用指南；确认版本保存在本机，旧用户也会看到新说明，设置可随时重看。没有根据审核身份、地区或远端开关隐藏功能，也不把确认按钮当成免除责任的协议。
- 保留原始记录、波形、自动分段、HRV、参考区间、节律参考分和早搏候选。候选和分数仍可能触发医疗用途审查；本次没有将它们宣称为已验证的医疗或筛查结果。
- 分段页面及 PDF 保留一般参考资料，移除按用户数值选择病因/用药解释和“本次中位数偏离参考范围”提示。旧的个体化疾病解释从语言资源中删除。核心测试覆盖所有语言、不同数值下不选择个体医学解释。
- Apple 原始分类及合成分类明确注明来源，取消根据分类给数值着色、加警示图标。每日入口改为“记录”表述；不会把没有提示解释为健康结论。
- PDF 页脚、使用指南、App Store 中英描述、网站方法/条款/隐私/指南同步更新。PDF 六语测试检查完整波形、长备忘和提醒；没有仅改商店文案而留下矛盾的个体病因输出。
- 隐私政策补充 TestFlight 平台信息：Apple 处理测试安装、会话、崩溃及主动反馈；这与 App 自身无健康上传服务分开披露。
- 增加 `Tools/check_appstore.py --external-testflight` 和[项目专用操作指引](../testflight-guide.zh-CN.md)。外部测试证据门槛与正式上架截图要求分开；没有把未验证的状态设为通过。

## 本次代码与配置检查

| 项目 | 证据与边界 |
| --- | --- |
| 数据流 | App 没有 URLSession 上传、远程 AI、广告/跟踪或统计 SDK；仅系统 HealthKit、本地 SwiftData/文件及用户主动分享 PDF/打开链接/发邮件。第三方依赖是本地 HeartProCore，未添加第三方采集 SDK |
| HealthKit | 读取 ECG、心率、SDNN；写入仅由用户选择症状后请求；不写原始 ECG、自动结果或合成数据；读取拒绝不能由 HealthKit 直接判断 |
| 存储 | 受保护本地目录、排除备份、CloudKit `.none`、非活跃状态遮挡；清空覆盖本地记录/备忘/波形/临时 PDF，保留 Health 原始记录和用户已写症状 |
| 隐私清单 | 无跟踪；UserDefaults `CA92.1` 覆盖新增确认偏好；自身容器文件时间戳 `C617.1`。从 Release archive 读取并检查，不仅检查源码 |
| 登录/支付 | 无账号、订阅、IAP 或外链支付，无当前版本的账号删除/恢复购买需求；新增这些功能时重审 |
| 权限与地区 | 六语 Health 目的说明齐全；不以“非医疗建议”作为不披露健康数据访问的理由；不假定所有地区都有 Apple Watch ECG |
| 签名与版本 | Bundle ID `com.alkinum.heartpro`，0.6.0 (1)，iOS/iPadOS 18+，本机 Xcode 27.0 / iOS 27 SDK；无签名 archive 不能证明生产签名或 Apple 接受上传 |

## 验证记录

本轮核心测试、原生测试、网页测试、归档及截图的最终结果见下表和 `../evidence/testflight-2026-09-22/`。此前 2026-09-20 的验证只作为历史基线。

随后按用户要求优化了使用须知的视觉层次、正文对比度和 iPad 布局，新增三个六语分组标题。该调整的截图与定向验证单独记录在[使用须知设计复核](../evidence/usage-notice-design-2026-09-22/README.md)；下表的归档与源码哈希对应视觉调整前的合规修改基线，未因界面调整重新归档。

| 检查 | 本轮结果 |
| --- | --- |
| 核心 | 49 项通过；含所有语言下不生成个体病因解释的回归；不是临床准确度验证 |
| 六语资源 | 671 键、占位符和权限资源检查通过；不是母语医学术语审校 |
| 原生存储/PDF与首屏 UI | 11 项存储/PDF + 5 项 UI = 16 项通过；0 失败/跳过/运行时警告。大字号另外定向复测通过，验证完整紧急提示可滚动到可视区域且继续按钮可操作；见 native-tests-summary.json 和 notice-large-text.log |
| Release archive | 合规修改基线的无签名归档通过；archive-verified.log、archive-bundle.json、source-sha256.json。未完成 Organizer / App Store Connect 验证 |
| 网站 | 类型检查、严格内容检查、静态构建通过；最终 4 项浏览器测试通过（website-tests-verified.log），覆盖双语、手机、深浅色、页面与锚点；公开 HTTPS 仍未验证成功 |
| 截图 | 24 张中英 iPhone 6.9 英寸/iPad 13 英寸原始截图已更新并视觉复核；各 2 项截图流程通过，manifest 记录来源和哈希；网站 6 张预览同步更新 |
| 外部 TestFlight 门槛 | 预期失败：准确度、主体/地区、正式政策、真机 HealthKit、签名/Connect、账号资料仍未完成 |

初次原生构建发现拆出视图后缺少 ViewBuilder，随后修复；首次 UI 验证发现父级 accessibilityIdentifier 覆盖继续按钮，随后移除父级标识并重测。网站原有预览端口被占用，使用独立端口复测，没有终止其他服务。一轮预览首次加载出现 500 界面，未稳定复现；增加按路由的测试步骤后带 trace 重跑，16 个路由及其余浏览器测试全部通过，不能据此断言已定位首次异常根因。保留失败日志，最终结论只引用修复后的结果。

## 仍需实际证据的事项

1. **用途与个人主体**：Apple 1.4.1 关注医学相关测量方法和准确度；5.1.1(ix) 涉及健康服务/敏感信息的法律实体要求。个人账号能创建 TestFlight 构建，不代表本产品获得豁免。应如实确认实际用途与主体资格；保留相关功能就保留这项审查风险。
2. **真实数据验证**：现有开发基准不能代表 Watch 数据；按 Watch 方案执行独立标注验证，并按真机表验收。不得把 49 项测试或合成 UI 截图当成“医学有效”。
3. **正式运营和政策**：需要正式运营者姓名/主体、网站/邮箱服务商、保留期限、处理地区、生效日期、审核联系人。现有网站仍为草稿，App 内 HTTPS 链接本次请求失败；未发送支持邮件，不能认定邮箱可投递。
4. **地区**：明确地区后按实际用途核对适用的医疗软件、隐私、消费者及商店要求。欧盟 trader 身份、适用 GDPR/MDR 问题，中国大陆适用备案/数据/医疗软件要求需分别判断；不能直接勾选全球后声称各地均合规。
5. **分发**：正确 Team、HealthKit App ID 与分发签名、Organizer 验证、Apple 处理、Beta 联系资料及外部审核均待用户账户完成。审核资料必须披露现有分析功能。

## 官方依据

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：1.4.1、2.2、5.1.1(ix)、5.1.3；本次重新在线核对。
- [外部测试](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)：首次审核、Internal Only 限制和内部组前置。
- [上传构建](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)与[近期要求](https://developer.apple.com/news/upcoming-requirements/)：最低工具链不等同提交成功。
- [App Privacy](https://developer.apple.com/app-store/app-privacy-details/)：仅设备内处理不计为标签中的 collected，网站/邮件/TestFlight 平台数据需分开评估。

这些检查不构成 Apple 审核承诺或跨地区法律定性结论。

可直接查看[新版中文首次使用须知](../evidence/usage-notice-design-2026-09-22/zh-usage-notice.png)、[视觉调整前的六语截图](../evidence/testflight-2026-09-22/usage-notice-contact-sheet.jpg)、[中文合成 PDF](../evidence/testflight-2026-09-22/report-zh-Hans.pdf)。
