# HeartPro 提审材料使用顺序

当前：2026-10-13，0.6.0 (4)，`com.alkinum.heartpro`，品牌 HeartPro。已使用用户授权的个人团队完成归档、验证、上传及 Apple 处理，Internal 已加入，PB 为 Testing，正式 App Store 为 Waiting for Review，保留审核通过后手动发布。六语文案、测试说明和必填 iPhone/iPad 素材已更新；USD 2.99 保留，SGD 改为 3.99；供应 174 个地区，排除中国大陆。最新事实见 [build 4 交付记录](../evidence/build-4-2026-10-13/README.md)。

已完成检查见[本轮验证记录](validation.md)。正式中英政策、条款和支持页面源文件在 `website/content/pages/`；生产可访问状态与邮件收信分别验证，见最新核对。

## 1. 先填 App Information

| Connect 字段 | 材料 |
| --- | --- |
| 平台 / Bundle ID | iOS（iPhone、iPad） / `com.alkinum.heartpro` |
| 主要语言 | 建议 English (U.S.) |
| 名称、副标题 | 对应 `../metadata/<locale>/name.txt`、`subtitle.txt` |
| 类别 | 主类别健康健美（Health & Fitness），用户已确认；第二类别暂不选 |
| Privacy Policy URL | 英文 `https://heartpro.alkinum.com/privacy/`；中文 `https://heartpro.alkinum.com/zh/privacy/`。正式政策已部署并验证 HTTPS；详见本轮证据 |
| 年龄分级 / App Privacy / 医疗器械状态 | [逐项填写依据](privacy-and-rating.zh-CN.md) |
| Copyright / 价格 / 地区 / 联系人 | Copyright：`2026 [REDACTED PERSONAL NAME]`；USD 2.99 基准价、联系人已保存；使用 [REDACTED PERSONAL NAME] 个人团队；174 个当前国家或地区，排除中国大陆，已保存 |

名称能否使用、Bundle ID 所属 Team、SKU 是否唯一，需在实际账户中检查。当前版本仍为 0.6.0，不擅自改为 1.0.0；已上传过 Build 1 时需要递增构建号并更新对应材料。

## 2. 填六语版本信息

每种语言都有 `name`、`subtitle`、`description`、`keywords`、`promotional_text`、`whats_new` 六个文本文件。

| Connect 语言 | 文案目录 | 截图文件前缀 | 政策/支持网站语言 |
| --- | --- | --- | --- |
| English (U.S.) | `../metadata/en-US/` | `en-` | 英文 |
| Chinese (Simplified) | `../metadata/zh-Hans/` | `zh-Hans-` | 简体中文 |
| Japanese | `../metadata/ja/` | `ja-` | 英文，描述中已说明 |
| Korean | `../metadata/ko/` | `ko-` | 英文，描述中已说明 |
| German | `../metadata/de-DE/` | `de-` | 英文，描述中已说明 |
| Spanish (Spain) | `../metadata/es-ES/` | `es-` | 英文，描述中已说明 |

`whats_new.txt` 保留首版功能摘要；Apple 首次版本不提供 What's New 字段，留作后续版本参考，不另找字段硬填。这次标签修复进入审核操作说明、TestFlight 测试任务和截图，不改写首版摘要为已发布版本的更新日志。新增的四语文案已做语义与长度复核，尚未经过独立母语审校。

完整可复制字段和有序图片列表见 [connect-payload.json](connect-payload.json)。它是本地交付数据，**不是可直接 POST 的 Apple API 请求体**。其中 `submission_ready` 和 `external_testflight_ready` 保持 false；公开 HTTPS 页面已独立验证，支持邮件投递仍待验证。

## 3. 上传截图

每语种每设备 6 张，三个设备组共 108 张。全部来自真实模拟器 App 界面、标注为合成示例，无个人健康记录。无需把截图额外套进设备模型；直接上传原始 PNG。

| Connect 设备组 | 文件夹 | 原始尺寸 |
| --- | --- | --- |
| iPhone 6.3-inch（本账户当前必填） | `../screenshots/iphone-6.3/` | 1206 × 2622 |
| iPhone 6.9-inch（选填） | `../screenshots/iphone-6.9/` | 1320 × 2868 |
| iPad 13-inch | `../screenshots/ipad-13/` | 2064 × 2752 |

各语言推荐顺序：**04-waveform → 01-history → 02-daily → 03-trends → 05-note → 06-privacy-settings**。最后一张为设置/隐私入口，可选；没有将链接可点击等同政策已上线。文件名前缀与语言对应，不能把 `de-` 图片误传给日语。

联系表仅供选图，不上传商店；`reference-only/` 为旧版历史图，不在本次交付包。素材清单记录 PNG 哈希、版本和来源。iPad 系统状态栏日期仍跟随模拟器系统语言，App 内文本按相应语言显示。

本组图片已于 2026-10-13 从 HeartPro 构建 4 源码重新捕获，三个设备组六语联系表均已复核。必填 iPhone/iPad 共 72 张已替换到 Connect；选填大屏 iPhone 关联保留既有素材。此前缩放、深色大字号及全屏证据见[波形标签验证](../evidence/wave-labels-2026-10-10/README.md)。若后台已经填写或上传旧材料，需要替换截图、Notes 与 What to Test；本地包更新不会自动同步 App Store Connect。

## 4. App Review Information

- Sign-in required：**No**。无需用户名/密码；审核员通过普通用户同样可见的合成示例模式查看全部现有功能。
- Notes：复制 [英文审核备注](../review-notes.txt)。文案明确披露首次使用须知、HealthKit 读写、早搏候选、节律参考分和准确度证据现状，没有借示例模式隐藏功能。
- Notes 上限按 4000 UTF-8 字节校验；已保存的审核说明为 3796 字节。
- Contact：用户提供的真实姓名、邮箱、电话已保存于 Connect，不在公开仓库复写私人联系资料。
- Attachment：见 [审核附件与证据清单](review-attachments.zh-CN.md)。当前合成 PDF、截图仅能证明界面/导出，不替代准确度报告。

## 5. 外部 TestFlight

TestFlight → Test Information 按语言复制 `../testflight/beta-description.<locale>.txt`；构建的 What to Test 使用 `../testflight/what-to-test.<locale>.txt`。二者分别说明产品和测试任务，不再把商店描述直接当成测试清单。Beta Review Notes 可用同一份英文审核说明，但提交前必须更新任何已变化的验证事实。

2026-10-11：Beta 反馈邮箱使用用户提供的开发者联系邮箱，真实审核联系人、六语 Beta 描述/测试任务和英文审核备注均已在 Connect 保存。支持邮箱 `support@heartpro.alkinum.com` 的独立投递验证仍待完成；没有把它写成已验证的反馈渠道。详细 Xcode 签名、Archive、Upload、外部组和 Beta App Review 步骤见 [TestFlight 指引](../testflight-guide.zh-CN.md)。

## 6. 提交与发布前的未完成项

材料检查通过不等同分发就绪。当前仍缺：真实 Watch 准确度/适用用途证据、主体与地区判断、支持邮箱投递、真机 HealthKit 验收、独立监管/主体适用性审查；Xcode 上传与 Connect 构建处理已完成。具体证据状态见 [readiness.json](../readiness.json)。

用户已授权暂缓新增上述独立验证并提交 build 4；后台已接收提交不代表这些证据完成，也不代表正式审核通过。首次发行建议选择 **Manually release this version**，审核通过后自行决定发布时点。不要把上传成功、Beta 审核、正式 App Store 审核视为同一步。

## 维护和重新打包

在仓库根目录运行：

```sh
rtk proxy python3 Tools/package_appstore.py
rtk proxy python3 Tools/check_appstore.py
rtk proxy python3 Tools/package_appstore.py --check
rtk proxy python3 Tools/package_appstore.py --zip
```

生成根目录的 `HeartPro-AppStore-0.6.0-4-preparation.zip`，包含字段、图片、操作表和文件哈希清单；这是准备材料包，不是 IPA 或可上传的 Xcode archive。`--submission` / `--external-testflight` 门槛检查在当前未完成状态应继续失败。

字段要求依据：[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)（关键词上限为 100 UTF-8 字节）、[Localize app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/)、[Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)。本轮在线核对记录随包附带。
