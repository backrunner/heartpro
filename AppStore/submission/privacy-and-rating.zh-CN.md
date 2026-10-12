# 隐私、年龄分级与地区申报填写依据

核对日期：2026-09-22。对象为当前 HeartPro 0.6.0 源码。以下是基于当前功能的建议答案；尚未在 App Store Connect 保存或提交。2026-10-09 已确认运营者 Alkinum（组织）、Cloudflare 托管和支持服务、健康健美主分类及全球发行目标。价格、审核联系人、各地区申报和支持邮箱投递仍待核验。

## App Privacy

当前 App Privacy 总问题建议选择 **No, we do not collect data from this app → Data Not Collected**。Apple 对 collected 的定义涉及从设备传出并由开发者或第三方合作伙伴访问；仅在设备处理的健康记录不属于该标签中的 collected。

| 项目 | 当前处理方式 / 填写依据 |
| --- | --- |
| Health & Fitness | HealthKit 的 ECG、电压波形、心率、SDNN，以及可选症状；在设备上处理，不发往开发者或合作方服务器 |
| User Content | 本地备忘和用户主动导出的 PDF；没有云端备忘、上传表单或自动附件采集 |
| Identifiers / Usage Data / Diagnostics | 没有账号标识、广告标识、开发者统计或崩溃 SDK |
| Tracking | No；无跨应用广告跟踪，无 tracking domains，不申请 ATT |
| UserDefaults | 隐私清单 `CA92.1`，本 App 的首次指南、使用须知确认和偏好 |
| File timestamps | 隐私清单 `C617.1`，本 App 容器中的缓存与临时报告时间 |
| 用户主动分享 | 由系统分享面板发送至用户指定对象；接收方的处理规则适用；不能宣称已分享副本也能被本 App 删除 |
| 支持邮箱 / 产品网站 | 独立通信和网站访问由正式政策披露。App 仅打开外部链接；用户确认 Cloudflare 为服务商，网站已部署。支持邮箱投递及实际邮件处理配置仍待核验，不承诺固定存储地区或未经验证的保留期限 |
| Apple 的 TestFlight 信息 | Apple 处理测试安装、会话、崩溃和测试者主动反馈；不能因此宣传“任何地方都不处理任何信息”。由 Apple 收集的信息与 App 自建采集分开判断 |

自愿反馈的 optional disclosure 有完整适用条件，不能仅凭“用户自愿”一项就豁免所有后续客服/遥测数据。若增加 App 内表单、自动附加日志、云同步、服务器分析或统计 SDK，重新判断标签。App Privacy、二进制隐私清单、HealthKit 权限说明、隐私政策 URL 是四项不同材料。

中英政策已按 2026-10-09 用户提供资料定稿。生产部署与公开访问结果见 [最新核对](../validation/health-fitness-2026-10-09.md)；2026-09-22 的网络检查仅是历史证据。支持邮箱的真实投递单独验证。

## 当前年龄分级问卷建议

路径：**General → App Information → Age Ratings → Set Up / Edit**。依据 Apple 当前问卷定义作答，由 Connect 计算全球及地区分级；不要手工承诺 4+。旧于 OS 26 的分级另有展示。

| 问卷项 | 建议答案 | 依据 |
| --- | --- | --- |
| Parental Controls / Age Assurance | No | 无家长控制或年龄验证；使用须知确认不属于年龄验证 |
| Unrestricted Web Access | No | 没有可任意浏览的内置浏览器，资料链接交由外部浏览器打开 |
| User-Generated Content | No | 没有向其他用户发布内容的社区；私人备忘与系统分享不同于 App 内公开内容平台 |
| Messaging and Chat / Social Media | No | 无用户聊天、社交动态或用户关系 |
| Advertising | No | 无广告 |
| Medical or Treatment Information | Frequent（保守建议，提交时按完整内容核对） | ECG 分类、间隔/参考值说明、节律候选解释和就医提示贯穿记录及帮助页；不是仅出现一次的背景文字。免责声明不消除这些内容 |
| Health or Wellness Topics | Yes（保守建议） | 有日常状态记录、睡眠/压力影响说明和在相似条件下比较 HRV 的建议；不宣称有个性化生活方式干预或饮食/运动计划 |
| Alcohol / Tobacco / Drug references | Infrequent（保守建议） | 有咖啡因背景标签和不要自行开始/停止用药的文字；官方定义包含合法或非法物质。无娱乐性药物、酒精或烟草使用场景；填表时按 Apple 示例复核 |
| Profanity / Horror / Mature or Suggestive / Sexual Content / Nudity | None | 无此类内置内容 |
| Cartoon / Realistic / Graphic Violence、Guns or Weapons | None | 无此类内容 |
| Gambling / Simulated Gambling / Contests / Loot Boxes | No / None | 无相关功能 |
| Made for Kids / Age Override | Not Applicable | 不是儿童产品；没有擅自追加 EULA 最低年龄。Apple Watch ECG 的硬件适用条件不等同 App 的内容分级 |

按当前官方表，Frequent Medical or Treatment Information 对 OS 26+ 的全球年龄分级对应 16+；最终结果以 Connect 实际计算、地区规则及最终问卷为准。这是内容分级，不是医疗器械定性。

## Regulated Medical Device Status

Apple 当前文档要求：在 **EU/EEA、UK 或 US** 提供，且主/副类别为 **Health & Fitness / Medical**，或年龄问卷选择 Frequent Medical or Treatment Information 的 App，需要申报受监管医疗器械状态。HeartPro 的当前 Health & Fitness 类别已触发需要核对此字段的条件，不能通过改年龄问卷规避。

路径：**General → App Information → App Store Regulations & Permits → Declare Regulated Medical Device**；Account Holder / Admin 操作。

- 当前答案：**待按实际用途及地区核定**。不把“没有取得许可”直接填成 No，也不把候选分析直接写成已批准医疗器械。
- 若适用结论为 No，按经确认的实际用途申报并保留依据。
- 若为 Yes，按地区提供法规所需注册/授权资料、EU Manufacturer SRN 或 FDA Owner/Operator Number（适用时）、Instructions for Use URL、Use Statement、Safety Information 及真实联系人。不得编造编号、CE/UKCA/FDA 状态。
- 商店文案的“非医疗建议”与首屏须知属于真实功能边界说明，不替代上述定性。

## 其他字段

| 项目 | 建议 / 待填状态 |
| --- | --- |
| Category | 用户确认主类别健康健美（Health & Fitness），第二类别暂不选；仍按实际功能接受审核 |
| Encryption | 当前仅使用系统数据保护，`ITSAppUsesNonExemptEncryption = NO`；以最终上传包为准 |
| Content Rights | 当前自制界面/图标、本地生成示例，不打包第三方 ECG 数据；如新增第三方素材需逐项确认权利 |
| Accessibility Nutrition Labels | 暂不勾选未完整评估的支持声明。六语大字号/深浅色局部测试不等于全 App VoiceOver、对比度、语音控制等认证 |
| Mac / Apple Vision Pro availability | 当前只验收 iPhone/iPad；新增平台可用性前单独检查 HealthKit、布局和交互 |
| Territories | 保留“尽量多地区”的意向，不把六语本地化等同全球可发行许可；具体列表仍待核定 |
| EU DSA / China mainland / Korea 等地区资料 | 按最终可用地区完成平台对应问卷、备案或证明，不能凭个人账号自动选豁免 |

## 官方来源

- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)
- [Declare regulated medical device status](https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status/)

本轮在线文档快照位于 `../evidence/submission-materials-2026-09-22/`。
