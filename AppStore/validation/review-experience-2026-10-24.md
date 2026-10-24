# 同类产品与审核经验核对

核对日期：2026-10-24。只读公开资料；没有联系其他开发者，没有核验其私人审核记录、开发者会员类型或法律资质。

## 可直接借鉴的引用整改

[GainFrame 开发者的公开经历](https://www.reddit.com/r/iosapps/comments/1roe53q/i_got_rejected_from_apple_8_times_finally_got/)自述经历多轮拒审，针对 1.4.1 增加了设置中的医学来源页面与链接，并补充医疗限制说明后获批。该帖子是开发者自述，不是苹果的通用先例。

[官方上线文章](https://gainframe.app/blog/gainframe-is-live/)和[商店页面](https://apps.apple.com/us/app/gainframe-progress-photos/id6759252082)可交叉确认产品已上架；商店公开卖家是 Michael Rode。它是健身照片/体成分产品，采用远程 AI 和不同的数据处理方式，不等同 HeartPro 的单导联记录估算。本轮未找到它曾因同一 5.1.1(ix) 组织账号要求被拒、再凭纯本地架构申诉成功的可核验记录。不能据此保证个人账号获准。

可借鉴：让来源入口容易找到、逐条对应健康信息、提供清楚的用途和限制、使用完整演示流程。其帖子提到的权限引导改动不能直接照搬；HeartPro 保留无健康授权的独立合成示例，不强迫授权。

## 相近的本地记录产品

[Heart Reports](https://apps.apple.com/us/app/heart-reports/id1448243870)公开卖家为 Viszt Peter，展示 Data Not Collected，强调本地生成报告、开发者无法读取健康数据。可以参考其记录查看与导出定位和清楚的数据边界。公开卖家名称不足以证明会员注册类型；本轮没有找到其具体拒审、申诉、组织账号豁免过程。

## 不能误当作个人账号先例

[ECG+](https://apps.apple.com/us/app/ecg-your-watch-ecg-reader/id1567047859)公开卖家为 Heartworks Pty Ltd，不能作为个人会员获准的证据。相同数据类型、不同功能、不同审核时期或已上架状态，都不证明 HeartPro 自动满足现行规则。

## 正式规则与本次决定

- [1.4.1 与 5.1.1(ix)](https://developer.apple.com/app-store/review/guidelines/)分别涉及健康信息/测量准确性和主体要求；加免责声明、引用或改叫记录不能替代实质合规判断。
- [健康与健身应用指引](https://developer.apple.com/health-fitness/)要求准确披露健康功能、请求必要权限并遵守敏感信息要求。
- [隐私标签定义](https://developer.apple.com/app-store/app-privacy-details/)区分设备本地处理和开发者/合作方可访问的设备外采集；不是主体要求的自动豁免。
- [申诉流程](https://developer.apple.com/help/app-review/after-submitting-for-review/appeal-to-the-app-review-board)要求先就具体拒审澄清，再按适用情形申诉。
- [个人会员转组织](https://developer.apple.com/help/account/membership/updating-your-account-information/)是组织会员转换，不是用于内部员工分发的 Apple Developer Enterprise Program。

用户最新决定：提交推送源码，保持现有 TestFlight；不上传新构建、不重新提交正式审核、不发送回复或申诉。回复仅为未发送草稿，后续考虑转组织账号。信息性测量工具、不作为医疗器械使用及可能出错的文案表达预期用途，不宣称已取得独立法律或监管定性。
