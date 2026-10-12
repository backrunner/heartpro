# App Store 审核核对（历史基线）

2026-10-09 更新：运营者和版权人改为 **Alkinum**，按组织名义准备提交，目标全球发行；主类别为 **Health & Fitness（健康健美）**。此决定替代以下历史个人账号意向。Apple 组织账户和地区资格仍待核验，最新状态见[本轮核对](validation/health-fitness-2026-10-09.md)。

以下自 2026-09-20 起的表格与阻塞项为历史基线。**当前填写与发布状态只使用 [2026-10-10 核对](validation/health-fitness-2026-10-09.md)及 `readiness.json`**；官网已部署、运营者/版权已确认，不能按下列历史缺项重填。

**2026-09-22 历史更新**：当时范围、账号和测试结论见[本轮核对](validation/compliance-2026-09-22.md)。个人账号与外部 TestFlight 已确认；独立使用须知不能证明 App 不受 1.4.1 或 5.1.1(ix) 约束。以下为此前基线，不把历史构建和截图当成此次修改后的证据。

结论：**材料准备中，当前不得标记为可提交。** 保留全部分析功能；真实 Apple Watch 准确度验证通过后再提交。Apple 审核结果及医疗产品法律定性不能由本次代码检查保证。

## 已核对与修正

| 条目 | 当前证据及结论 |
| --- | --- |
| 标识一致 | XcodeGen、生成工程与编译产物均为 `com.alkinum.heartpro`。新 bundle 不会覆盖/迁移旧 bundle 的沙盒；如有旧测试版备忘需用户主动导出，不删除旧 app |
| 目的说明 | 六语 ECG、日常心率、HRV 读取；可选症状写入用途文案齐全；首次连接仅请求三个读取类型 |
| 最小写入 | 症状写入由用户选项触发，只申请所选受支持类型的写权限；移除从未使用的症状读权限；不写算法结果、模拟样本或原始 ECG |
| 用户拒绝权限 | HealthKit 无法判断读取被拒绝；空数据和不可用设备有说明与示例模式，不把请求完成当成已获得每项读权限 |
| 隐私清单 | 补齐 UserDefaults `CA92.1`；保留自身容器时间戳 `C617.1`；无跟踪/服务器采集声明 |
| 本地数据 | SwiftData `.none` CloudKit；受保护目录、排除备份；后台内容遮挡；无账号/分析服务器/统计 SDK |
| 数据清空 | 原来只删除数据库/波形，遗漏临时 PDF；现已加入临时报告清理，新增隐私删除回归用例，11 项原生测试通过 |
| 政策入口 | 设置增加隐私政策、支持网页和支持邮箱；六语标签；网页上线前仍是外部链接阻塞项 |
| 模拟演示 | 真实 UI 的合成示例模式，不冒充个人数据；禁止写入 Health；可供审核员无账号使用 |
| 医疗文案 | 已有非诊断、不可排除心梗/缺血、自动估算限制、HRV 与 5 分钟标准不同、紧急症状就医提示；保留限制，未假称监管许可 |
| 支付/账号 | 当前无账号、IAP、订阅、外链支付、广告或跟踪；不存在此版本账号删除/恢复购买入口需求；未来添加必须重新审查 |
| 图标/商店描述 | 自制 RGB 无 alpha 1024 图标；中英元数据字段长度检查；不宣称医学准确度、获批或 Apple 背书 |
| 网站 | 参照 ezarchive，以 svedocs 0.2.1 构建中英 16 页；本地搜索，无健康上传表单或客服服务器集成；没有复制其他产品密钥 |
| 当前截图 | 0.6.0 中英 iPhone 6.9 英寸、iPad 13 英寸共 24 张；原始 PNG 和 manifest，使用合成示例数据；网站已替换历史图 |
| 构建 | 当前 Release iOS 无签名构建成功、核心 48 测试通过；不等于 App Store 签名/上传验证或真机 QA |

## 提交前阻塞项

1. **Review 1.4.1 准确度与方法证据。** 本项目自动分段、早搏候选、节律分及超短时 ECG HRV 尚缺真实 Watch 独立标注验证。八条 MIT-BIH 开发审计中的 43.78% 检出率及复杂节律漏检，不能支持“可靠筛查”。实施 `validation/watch-accuracy-protocol.md`，审阅方法、覆盖率、错误和适用条件，更新网站/商店文案。免责声明不能替代证据。
2. **医疗法规和提交主体。** 确认目标地区产品用途与监管定性；Review 5.1.1(ix) 涉及健康/敏感信息的法律实体要求需核对。用户尚未提供正式主体和联系人，不可推断 `Alkinum` 一定是注册主体。
3. **正式 HTTPS 隐私/支持页面。** `website/` 已实现；政策和条款标为草稿。须补全主体、服务商/保留期限/地区及有效日期，部署后验证无需登录、可公开访问。当前公开域名 HTTPS 检查未成功，不能直接作为已可用的 App Store URL。
4. **真机完整性。** 需要真实设备上同意/部分同意/拒绝/撤销、首次/历史同步、空数据、可选写症状拒绝和重试、清空数据/PDF、离线、锁屏恢复、长历史、iPad 适配、VoiceOver/大字体验。逐项记录见 `validation/device-checklist.md`。不得用模拟器示例证明真实 HealthKit 成功。
5. **商店分发及账户。** 注册正确 App ID 与 HealthKit；分发签名 archive、Organizer Validate、TestFlight 处理、隐私报告、正式审核联系人、地区、版权、价格及新版年龄问卷。当前没有上传或创建 App Store Connect 条目。

用户已决定本轮暂时跳过主体、地区和邮箱服务商资料；相关缺项仍是发布前门槛，不阻止审阅现有网站和上架素材。

## 官方依据（本次在线核对，快照见 evidence）

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：1.4.1、2.1、2.3.3、5.1.1、5.1.3。
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)：设备内处理不计作 collected；将网站/邮件与 App 数据流分别评估。
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)：iPhone 6.9 及 iPad 13 的当前像素规格。
- [Age rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)：当前分级问卷，不预填猜测年龄。
- [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)：2026-04-28 起 Xcode 26+/iOS 26 SDK；2026 新年龄分级、EU trader 要求。当前 Xcode 27 满足最低版本数字，但正式 SDK/上传接受性仍以提交时 Apple 实际验证为准。
- [Required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)：对照实际调用填写理由，不随意声明未使用的 API。
