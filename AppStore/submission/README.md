# HeartPro 提审材料使用顺序

本轮：2026-09-22，0.6.0 (1)，`com.alkinum.heartpro`。这是可继续填写的本地准备包，尚未上传或提交 Apple 审核。运营者、版权、审核联系人、价格按用户要求暂不补填；不提供虚构值。

已完成检查见[本轮验证记录](validation.md)。政策、条款和支持页的中英草稿一并随包提供在 `website/content/pages/`，需要完成运营资料后才能作为正式政策发布。

## 1. 先填 App Information

| Connect 字段 | 材料 |
| --- | --- |
| 平台 / Bundle ID | iOS（iPhone、iPad） / `com.alkinum.heartpro` |
| 主要语言 | 建议 English (U.S.) |
| 名称、副标题 | 对应 `../metadata/<locale>/name.txt`、`subtitle.txt` |
| 类别 | 建议 Health & Fitness，最终按实际用途确认 |
| Privacy Policy URL | 英文 `https://heartpro.alkinum.com/privacy/`；中文 `https://heartpro.alkinum.com/zh/privacy/`。政策定稿且 HTTPS 可访问后才能当作最终值 |
| 年龄分级 / App Privacy / 医疗器械状态 | [逐项填写依据](privacy-and-rating.zh-CN.md) |
| Copyright / 价格 / 地区 / 联系人 | 待填；账号性质已确认是个人 |

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

`whats_new.txt` 保留首版功能摘要；首次版本表单可能不显示 What's New，未出现时留作后续版本参考，不另找字段硬填。新增的四语文案已做语义与长度复核，尚未经过独立母语审校。

完整可复制字段和有序图片列表见 [connect-payload.json](connect-payload.json)。它是本地交付数据，**不是可直接 POST 的 Apple API 请求体**。其中 `submission_ready` 和 `external_testflight_ready` 保持 false；URLs 也没有伪标为已验证。

## 3. 上传截图

每语种每设备 6 张，共 72 张。全部来自真实模拟器 App 界面、标注为合成示例，无个人健康记录。无需把截图额外套进设备模型；直接上传原始 PNG。

| Connect 设备组 | 文件夹 | 原始尺寸 |
| --- | --- | --- |
| iPhone 6.9-inch | `../screenshots/iphone-6.9/` | 1320 × 2868 |
| iPad 13-inch | `../screenshots/ipad-13/` | 2064 × 2752 |

各语言推荐顺序：**04-waveform → 01-history → 02-daily → 03-trends → 05-note → 06-privacy-settings**。最后一张为设置/隐私入口，可选；没有将链接可点击等同政策已上线。文件名前缀与语言对应，不能把 `de-` 图片误传给日语。

联系表仅供选图，不上传商店；`reference-only/` 为旧版历史图，不在本次交付包。素材清单记录 PNG 哈希、版本和来源。iPad 系统状态栏日期仍跟随模拟器系统语言，App 内文本按相应语言显示。

## 4. App Review Information

- Sign-in required：**No**。无需用户名/密码；审核员通过普通用户同样可见的合成示例模式查看全部现有功能。
- Notes：复制 [英文审核备注](../review-notes.txt)。文案明确披露首次使用须知、HealthKit 读写、早搏候选、节律参考分和准确度证据现状，没有借示例模式隐藏功能。
- Contact：待填真实姓名、邮箱、电话；不要把占位文字粘到后台。
- Attachment：见 [审核附件与证据清单](review-attachments.zh-CN.md)。当前合成 PDF、截图仅能证明界面/导出，不替代准确度报告。

## 5. 外部 TestFlight

TestFlight → Test Information 按语言复制 `../testflight/beta-description.<locale>.txt`；构建的 What to Test 使用 `../testflight/what-to-test.<locale>.txt`。二者分别说明产品和测试任务，不再把商店描述直接当成测试清单。Beta Review Notes 可用同一份英文审核说明，但提交前必须更新任何已变化的验证事实。

反馈邮箱暂用用户此前提供的 `support@heartpro.alkinum.com` 作为准备值，真实收信尚未验证。审核联系人仍待填。详细 Xcode 签名、Archive、Upload、外部组和 Beta App Review 步骤见 [TestFlight 指引](../testflight-guide.zh-CN.md)。

## 6. 提交与发布前的未完成项

材料检查通过不等同分发就绪。当前仍缺：真实 Watch 准确度/适用用途证据、主体与地区判断、公开正式政策/支持页、真机 HealthKit 验收、生产签名与 Connect 验证，以及暂缓填写的账号字段。具体证据状态见 [readiness.json](../readiness.json)。

在这些事项完成、选择正确处理完成的构建后，才能在版本页 Add for Review 并提交。首次发行建议选择 **Manually release this version**，审核通过后自行决定发布时点。不要把上传成功、Beta 审核、正式 App Store 审核视为同一步。

## 维护和重新打包

在仓库根目录运行：

```sh
rtk proxy python3 Tools/package_appstore.py
rtk proxy python3 Tools/check_appstore.py
rtk proxy python3 Tools/package_appstore.py --check
rtk proxy python3 Tools/package_appstore.py --zip
```

生成根目录的 `HeartPro-AppStore-0.6.0-1-preparation.zip`，包含字段、图片、操作表和文件哈希清单；这是准备材料包，不是 IPA 或可上传的 Xcode archive。`--submission` / `--external-testflight` 门槛检查在当前未完成状态应继续失败。

字段要求依据：[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)（关键词上限为 100 UTF-8 字节）、[Localize app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/)、[Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)。本轮在线核对记录随包附带。
