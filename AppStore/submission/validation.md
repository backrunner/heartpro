# 当前材料验证

2026-10-13 当前 build 4：55 项核心测试通过，38 项 App/UI 的最终结果通过，18 项原生截图流程通过；Xcode 验证、上传和 Apple 处理完成。Internal 已加入，PB 为 Testing，正式 App Store 为 Waiting for Review。最新素材与价格记录见 [build 4 证据](../evidence/build-4-2026-10-13/README.md)。项目独立证据门槛保持未完成。

## 2026-10-11 历史材料验证

2026-10-11；HeartPro 0.6.0（3），`com.alkinum.heartpro`。个人运营者/版权人 [REDACTED PERSONAL NAME]，桌面名称 HeartPro，英文商店名称 HeartPro: ECG & HRV Diary，主类别 Health & Fitness。构建已上传、处理、验证并选入版本；后台资料已保存，尚未提交 Apple 审核。

| 检查 | 当前结果与证据 |
| --- | --- |
| 原生截图 | 通过；108 张 PNG、三个设备组六语共 18 项捕获流程；尺寸、RGB、哈希和源码指纹校验，见 `../screenshots/README.md` |
| 品牌视觉 | 通过；三个设备组的六语历史/设置及德语六场景复核，合成数据标签保留；具体范围在各 manifest。历史深色、大字号、缩放及全屏检查未在本轮重跑 |
| PDF 报告 | 通过；5 项 ReportTests，导出的合成 PDF 及实际渲染页已查看，见 `../evidence/connect-2026-10-10/build-3-reports/` |
| 六语内容 | 通过；677 个本地化键和资源检查，名称/描述/权限与 HeartPro 品牌同步；独立母语审校待验证 |
| Connect | 已完成；0.6.0（3）已验证并选入版本；108 张截图处理完成；六语资料、联系人、价格、地区、类别和隐私答复已保存，见 `../evidence/connect-2026-10-10/status.json` |
| 网站 | 通过；check、docs、build 与 4 项 Playwright；部署版本 `2fbc8e70-59e6-4dc9-90b2-4491586340b3`，中英隐私页面在浏览器核实。CLI HTTP 403 未作为验证成功 |
| 分发就绪 | 待验证；独立 Watch 准确度、监管/主体适用性、真机 HealthKit 与支持邮件投递四项缺口保留；`submission_ready` 与 `external_testflight_ready` 仍为 false |

本地材料校验与 ZIP 完整性检查不会替代 Apple 审核、商标清查或上述独立验证。

## 2026-10-10 历史材料验证

下列为当时的材料准备记录，主体、版本、截图数量与分发状态已由上述 10 月 11 日结果更新。

2026-10-10；HeartPro 0.6.0 (1)，`com.alkinum.heartpro`。运营者/版权人 Alkinum，准备以组织名义提交，主类别 Health & Fitness。以下为当前材料；本轮未上传 App Store Connect 或提交审核。

| 检查 | 当前结果与证据 |
| --- | --- |
| 六语商店截图 | 通过；72 张原始 PNG，iPhone/iPad 各 6 项截图流程通过，哈希、尺寸、RGB 及应用源码指纹一致；所有六语联系表目视复核，见 `../screenshots/README.md` |
| 波段标签 | 通过；3 项布局测试、iPhone/iPad 各 2 项 UI 流程；窄 QRS、最小缩放、深色大字号与全屏实际截图见 `../evidence/wave-labels-2026-10-10/`；iPad 横屏采用设备方向切换 |
| 审核备注 / TestFlight | 通过；Notes 与六语 What to Test 已补充 P/QRS/T 标签及点击测量；Notes 为 3944/4000 UTF-8 字节，六语测试说明长度通过 |
| 首版摘要 | 不适用更新日志；保留首版功能摘要。Apple 首版不提供 What's New 字段，不把开发期修复写成已发布版本更新 |
| 组织与网站状态 | 材料已同步 Alkinum 和已部署的正式中英政策/支持页；支持邮箱投递单独待验证 |
| 网站验证 | 通过；4 项 Playwright，Cloudflare 版本 `68c01fdb-8f8b-4d39-9370-a9f488df655c`；六张公开 WebP 与本地来源哈希一致，公开页面返回 200，见波段目录 `public-assets.json` |
| Connect 数据与 ZIP | 通过；重新生成 `connect-payload.json` 与准备 ZIP，图片映射、审核备注、测试说明和源文件一致；ZIP 带逐文件 SHA256 清单 |
| 本轮修改范围 | 仅提审文档、测试说明及材料检查工具；生产 App 源码未改，不重复已完成的原生 UI 流程 |
| 分发状态 | 待验证；`submission_ready` 与 `external_testflight_ready` 均为 false，两项门槛命令如实返回六项缺失证据，未完成门槛保留 |

独立 Watch 准确度、组织/地区资格、真机 HealthKit、支持邮件投递、生产签名及 Connect 账号字段仍待完成，见[当前上架核对](../validation/health-fitness-2026-10-09.md)。当前文件引用与材料校验通过不能替代这些证据。后台若已有旧材料，须按 `README.md` 替换；本地包不会自动更新后台。

官方字段核对（2026-10-10）：[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)明确 Notes 上限 4000 bytes、What's New 不用于首版；[Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)区分 Beta 介绍、反馈邮箱及可更新测试信息。本轮没有重新进行完整法规审查。

## 2026-09-22 历史验证

下列记录仅保留当时的验证范围，不用于当前政策部署、主体、截图或字段长度判断；九月构建不是当前修复后的分发包。

日期：2026-09-22。应用版本 0.6.0 (1)，只准备材料，未上传、提交审核、发布网站或联系测试者。

| 检查 | 结果 |
| --- | --- |
| iPhone 17 Pro Max / iOS 27 模拟器 | 六语截图流程 6 项通过，0 失败、0 跳过、0 运行时警告 |
| iPad 13 英寸 / iOS 27 模拟器 | 六语截图流程 6 项通过，0 失败、0 跳过、0 运行时警告 |
| 图片 | 72 张原始 PNG，全部 RGB 无 alpha；iPhone 1320×2868、iPad 2064×2752；各文件 SHA-256 与捕获清单一致 |
| 视觉复核 | 查看全部 12 组分语言联系表；另以原尺寸复核西语 iPhone 波形页，日期完整显示。合成数据/来源标签保留，页面内容加载完成，无阻断性裁切 |
| 商店元数据 | 六语共 36 个字段检查通过；关键词按 UTF-8 字节，范围 64–86 / 100；最长描述 3089 / 4000 字符 |
| TestFlight | 六语简介与六语测试说明齐全，均小于 4000 字符；审核备注 3431 / 4000 字符 |
| App 本地化 | 674 键六语资源、占位符检查通过 |
| Connect 数据 | `Tools/package_appstore.py --check` 通过，字段与截图映射和源文件一致 |
| 工作区差异 | `git diff --check` 通过 |
| 网站图片 | 6 张既有中英预览从本轮原生截图重新生成，来源哈希同步；没有修改网站行为，本轮未重跑网页测试或部署 |
| 正式提交 / 外部 TestFlight 门槛 | 均按预期失败，六类未完成证据仍保留；没有通过修改状态来绕过检查 |

截图结果包和源码指纹记录在 `../screenshots/<group>/manifest.json`；测试摘要在 `../evidence/submission-materials-2026-09-22/`。原始模拟器与 XCTest 日志在仓库中保留。使用须知大字号/深浅色的定向测试来自上一轮设计复核，本轮没有改动 App 生产代码。

本轮没有重新做 Release archive；既有无签名归档也不能证明生产签名或 Apple 接受上传。真实 Watch 独立准确度、真机 HealthKit、主体/地区定性和正式政策仍未完成。翻译没有经过独立母语审校；模拟器截图不能代替这些证据。

官方资料本轮已在线核对：商店字段限制、语言本地化、TestFlight 简介、App Privacy、年龄问卷与医疗器械状态。公开产品政策/支持页的 HTTPS 请求仍未成功，详见 `online-checks.json`。账号、版权、审核联系人与价格按用户要求暂留待填。
