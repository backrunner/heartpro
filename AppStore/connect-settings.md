# App Store Connect 填写表

此表记录当前 Connect 已保存字段；Apple 审核状态与项目验证门槛分别记录。包名已在工程与构建中设为 `com.alkinum.heartpro`，不可使用旧 `app.heartpro.ios` 创建条目。

2026-10-11：用户明确授权使用当前个人团队 **[REDACTED PERSONAL NAME]**，替代此前组织提交意向。Connect App ID 为 **6821359492**，显示品牌为 **HeartPro**。2026-10-13 当前 0.6.0（4）由 Xcode 上传成功，Connect 已处理、二进制已验证并选入版本；正式审核状态为 Waiting for Review，PB 为 Testing，见 [build 4 记录](evidence/build-4-2026-10-13/README.md)。名称核对见 [改名记录](validation/name-review-2026-10-10.md)，实际保存范围见 [Connect 状态](evidence/connect-2026-10-10/status.json)。

| 字段 | 准备值 / 操作 |
| --- | --- |
| Bundle ID | `com.alkinum.heartpro`；在正确团队注册明确 App ID，启用 HealthKit 并重新生成分发 profile |
| SKU | 建议 `heartpro-ios`；由账户内唯一性确认 |
| 名称 / 副标题 / 描述 / 关键词 | `metadata/` 中六语材料，详见 [填写顺序](submission/README.md)；关键词上限为 100 UTF-8 字节，其余按字符校验 |
| 版本 / 构建 | 当前 0.6.0 (4)，已上传、处理并选入正式待审核版本；每次重复上传递增构建号 |
| 类别 | 用户确认主类别为健康健美（Health & Fitness）；第二类别暂不选。按实际功能接受 Apple 类别及健康测量审核 |
| 平台 | iPhone、iPad；iOS/iPadOS 18+；无独立 Watch app |
| 主要语言 | 建议 English (U.S.)；商店材料与 App 均支持英、简中、日、韩、德、西六语 |
| Marketing URL | `https://heartpro.alkinum.com/`，已部署并验证 HTTPS |
| Support URL | `https://heartpro.alkinum.com/support/`；中文 `/zh/support/` |
| Privacy Policy URL | `https://heartpro.alkinum.com/privacy/`；中文 `/zh/privacy/`；正式政策已部署并验证 HTTPS |
| 支持邮箱 | `support@heartpro.alkinum.com`，由用户提供；本次未发送邮件或确认投递 |
| Copyright | `2026 [REDACTED PERSONAL NAME]`，已保存 |
| App Review 联系人 | 用户提供的姓名、邮箱、电话已保存于 Connect；不在公开仓库复写私人联系资料；示例模式不要求登录 |
| 内容权利 | 自制图标/界面；Apple 商标仅用于说明兼容性，未获背书；不打包公开测试 ECG 数据 |
| EULA | 无特殊条款时使用 Apple Standard EULA；网站条款不可替代或冲突法定消费者权利 |
| 价格 | US 基准价 USD 2.99；主要 USD/EUR/GBP/CAD/AUD/NZD 价位以 .99 结尾；SGD 手动调整为 3.99，其他币种保留附近可用档位（2026-10-13）；没有 IAP、订阅、付费解锁或外链支付 |
| 出口合规 | `ITSAppUsesNonExemptEncryption = NO`；仅平台保护，无自有非豁免加密；最终二进制须复核 |
| 分发地区 | 当前 174 个国家或地区，排除中国大陆；用户授权后已保存。不自动加入未来新地区。后台选区不代替地区法规核对 |
| 账户与商业协议 | 当前付费与免费协议有效，银行账户可用，税表使用中（2026-10-10 只读核实）；未代接受新协议 |
| 欧盟 DSA | 如在欧盟分发，准确声明 trader status 并提交所需公司/联系人资料 |
| 健康领域卖方 | [REDACTED PERSONAL NAME]（个人团队）；用户已授权此团队，但健康功能的主体要求仍须核对；仍须核对 Review 5.1.1(ix) 对当前功能的适用性，不声称已获主体例外 |
| Regulated Medical Device Status | 2026-10-11 按用户明确确认保存 No；主类别继续 Health & Fitness。用户声明不等于独立监管/主体适用性审查完成 |
| Accessibility Nutrition Labels | 暂不声明未经过全 App 评估的支持项目；局部 UI 测试不等同完整无障碍验收 |

## App Privacy 问卷

当前代码：不向开发者或合作方服务器发送健康数据、备忘、标识符、分析/崩溃遥测；无第三方 SDK、广告、跟踪或远程 AI。Apple 明确说明只在设备上处理的数据不算其标签中的“collected”。按此代码行为，填写 **Data Not Collected**，不申请 ATT。

此答案并不表示“不访问健康数据”。用途文案和隐私政策必须披露 ECG、心率、SDNN、可选症状及本地备忘。用户通过系统分享面板主动分享的 PDF、主动发送的支持邮件与独立网站日志分别解释；如未来新增表单、统计、服务器分析或客服自动上传，需要重新评估标签及隐私清单。不要复制其他产品的声明。

TestFlight 另由 Apple 处理安装、会话、崩溃和主动提交的反馈；政策已单列披露。这不等同 App 自行上传健康数据，不应把测试反馈描述成“完全没有任何信息处理”。

隐私清单：FileTimestamp `C617.1`（仅自己容器中文件缓存/报告时间）；UserDefaults `CA92.1`（AppStorage 首次指南、使用须知确认及偏好）。无 tracking domains，无服务器数据采集类别。清单不是隐私政策 URL 的替代。

## 年龄分级

逐项建议与官方定义见[隐私和分级填写表](submission/privacy-and-rating.zh-CN.md)。根据当前持续展示的心电解释/参考资料，医疗信息频率保守建议 Frequent，由 Connect 计算结果；不会为了获得更低年龄分级隐藏分析内容。

使用当前新版问卷，不能沿用旧版 4+/12+ 表格直接猜等级。健康/保健主题应如实选择；医疗/治疗内容频率应按自动间隔说明、参考范围、症状及医学解释的实际内容回答，不可因写了免责声明就选择“无”。无广告、社交聊天、UGC 社区、赌博、暴力、色情、外部无限制网页浏览等现有功能。最终由 App Store Connect 计算等级；ECG 硬件适用年龄和 App 内容分级是不同问题，不混为一谈。不选择儿童类别。

## 素材规格

当前账户媒体管理将带灵动岛中显示屏 iPhone 组列为必填，支持 1206×2622 或 1179×2556；本轮已为六语分别上传六张原生 6.3 英寸截图。大显示屏 iPhone 组列为选填，支持 1320×2868 / 1290×2796 / 1260×2736。支持 iPad 则需要 13 英寸组（2064×2752 或 2048×2732）。每组 1–10 张，PNG 或 JPEG；推荐各 5 张展示真实使用，保留合成数据标识。不要把旧 1206×2622 的 6.3 英寸图片改尺寸冒充新设备截图。

图标为 1024×1024 RGB PNG 无 alpha；普通/深色源文件均已导出。App Preview 视频可选，本次不制作。无实际 App Store ID 前不展示虚假的下载徽章或链接。

2026-10-11：用户授权后已发布隐私标签“未收集数据”；174 个当前国家或地区供应已保存，中国大陆显示“未供应”。后台资料字段已完成，尚未提交审核。
