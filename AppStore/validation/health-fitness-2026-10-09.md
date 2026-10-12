# HeartPro 健康健美与组织运营核对

本轮工作：2026-10-09 至 2026-10-10。版本 0.6.0 (1)，Bundle ID `com.alkinum.heartpro`。用户确认运营者/版权人为 **Alkinum**，使用组织名义，主类别 **Health & Fitness（健康健美）**，目标全球发行；网站和支持服务商为 Cloudflare。先前 BackRunner / [REDACTED PERSONAL NAME] 个人运营意向已被替代。

## 实现与材料

- 通过：设置使用正式 BrandMark，支持入口带图标，移除重复邮箱行；只在真实数据存在待处理或失败分析时显示重试。状态覆盖未加载的历史记录，清理、恢复和示例切换会更新。
- 通过：核心分析与健康数据留在设备，无网络请求客户端、云分析、跟踪或 CloudKit。HealthKit 读写仍使用系统授权；支持/政策链接由系统浏览器打开。不需要额外网络或本地网络权限。
- 通过：中英政策与条款明确 Alkinum、Cloudflare、设备数据、支持邮件用途/保留原则和跨境处理；商店版权为 `2026 Alkinum`。没有承诺未经验证的固定邮件保留期限。
- 通过：健康健美分类进入准备数据和审核备注。保留实际分析功能及准确度限制，不用分类或免责声明替代验证。

## 验证记录

最终截图、网站生产结果及测试摘要在 [本轮证据目录](../evidence/health-fitness-2026-10-09/)。原始 XCTest 包留在本地 `TestResults/`，不纳入 Git。截图清单保存构建、设备、文件哈希和应用源码指纹，提交检查拒绝与当前源码不一致的截图。

| 验证 | 结果与范围 |
| --- | --- |
| 六语翻译 | 通过；677 个条目，覆盖与占位符匹配。 |
| 核心测试 | 通过；55 项。 |
| PDF / 权限翻译 | 通过；5 项 ReportTests，含六语报告、完整波形、长备忘、实际候选与临时 PDF 清理。 |
| 持久化/重试 | 通过；7 项 RepositoryTests，含未加载历史失败、示例切换、恢复、删除/清空。 |
| 原生设置 UI | 通过；真实用户首次须知流程，确认无未完成分析时没有重试入口。 |
| 商店截图 | 通过；iPhone / iPad 各 6 项截图流程，共 72 张原始 PNG；六语标准字号/竖屏已目视复核。波形标签深色大字号及全屏定向检查通过；全 App 大字号、减少透明度和完整 VoiceOver 仍待验证。 |
| 网站源码/内容 | 通过；Svelte 0 错误/警告，16 页/80 搜索记录双语检查通过，静态构建与部署 dry-run 通过。 |
| 网站交互 | 通过；4 项 Playwright，覆盖 16 条内容路由、中英桌面/手机、主题、预览图、搜索、锚点、404 与机器可读输出；中英最终预览截图已目视复核。 |
| 生产 HTTPS | 通过；初次部署版本 `616215db-ced6-406f-951b-0d0655cb99ea` 的 15 条路径经 TLS 校验返回预期状态，Alkinum 政策公开，`/tos` 与 `/zh/tos` 跳转对应条款；Edge 打开中文政策核对实际显示。 |

2026-10-10 后续：窄 QRS 标签隐藏及缩放后轨道偏移已修复，完整标签/碰撞排布与范围边界分开，相关 iPhone/iPad 标准/深色大字号及全屏验证见[波形标签记录](../evidence/wave-labels-2026-10-10/README.md)。商店和官网截图已从修复版本刷新；最新 Cloudflare 版本为 `68c01fdb-8f8b-4d39-9370-a9f488df655c`，公开六张图片哈希及中英公开页面状态见该目录 `public-assets.json`。审核备注、六语测试说明和填写指引同步本轮状态，首版功能摘要保留。

## 提交前仍需完成

| 项目 | 状态与依据 |
| --- | --- |
| Apple 组织账户/卖方 | 待验证；Cloudflare 的 Alkinum 账户及用户确认不能证明 Apple Developer 已登记相应法律实体。需核对组织法定名称、Team、卖方及健康领域主体资格。 |
| 全球地区申报 | 待验证；逐地区核对医疗器械定性及声明、EU trader 信息和适用监管要求。不可直接把所有地区医疗器械状态填 No。 |
| Watch 独立准确度 | 待验证；现有合成/公共基准不能替代 Watch 记录验证，方法与参考分仍如实披露。 |
| 真机 HealthKit | 待验证；完整读取、撤权、可选症状写入、同步/删除、分享/清理按 device-checklist 验收。 |
| 分发签名 / Connect | 待验证；未制作本轮生产签名 archive、上传构建或完成 Apple validation。审核联系人、价格仍需实际资料。 |
| 支持邮箱投递 | 待验证；已检查的 `heartpro.alkinum.com` MX 查询为空，区域 Email Routing 未发现该支持地址规则；未发邮件。域名 HTTPS 部署不证明邮箱可收信，必须补齐真实收信配置并验收。 |

`submission_ready` 与 `external_testflight_ready` 保持 false。Apple 决定类别及审核结果；组织名义与健康健美类别不能单独证明全球上架合规。

## 规则依据

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：1.4.1 健康测量方法/准确度，2.3.5 类别，5.1.1(ix) 敏感信息及高度监管服务的法律实体，5.1.3 健康数据用途与存储。
- [App Store 类别](https://developer.apple.com/app-store/categories/)：按实际用途选择，类别不能决定监管定性。
- [App Privacy](https://developer.apple.com/app-store/app-privacy-details/)：设备内处理与服务器收集分别判断。
- [医疗器械状态申报](https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status/)：目标地区与实际用途决定申报。
