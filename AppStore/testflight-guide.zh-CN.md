# HeartPro：Xcode 构建与外部 TestFlight 指引

核对日期：2026-10-13。项目：`HeartPro.xcodeproj`；scheme：`HeartPro`；Bundle ID：`com.alkinum.heartpro`；版本：`0.6.0 (4)`；最低系统：iOS/iPadOS 18。

当前使用用户授权的个人团队和 HeartPro 品牌。0.6.0（4）已上传、处理和验证，Internal 已分配，PB 显示正在测试，正式 App Store 版本正在等待审核。审核通过后手动发布。当前 174 个地区开放供应，中国大陆排除，隐私标签已发布。Apple 分发状态与项目准确度、监管、真实 HealthKit 等证据分别记录，详见 [build 4 记录](evidence/build-4-2026-10-13/README.md)。

## 2026-10-13 build 4 分发

0.6.0（4）已完成 Release 归档、Xcode 验证和上传。Connect 实际分发二进制显示已验证、HealthKit=true、get-task-allow=false；Internal 和 PB 均已分配，PB 显示正在测试，公开链接继续使用 https://testflight.apple.com/join/qXWxxJev 。六语言测试内容、趋势描述和必填 iPhone/iPad 截图已更新。USD 2.99 保留，主要美元、欧元、英镑、加元、澳元、新西兰元现价均以 .99 结尾；SGD 从 3.98 改为 3.99，其他没有附近合适 .99 档位的货币保留当地价位。正式版本已选择 build 4，并按用户指令提交，Connect 显示正在等待审核；发布方式保留审核通过后手动发布。当前提交结果见 [build 4 记录](evidence/build-4-2026-10-13/README.md)。

本轮核心 55 项测试通过；App/界面 38 项测试的最终结果均通过，包含修正过时测试后的针对性重跑。新增两项导航修复已用独立 HeartProFix 0.6.0（3）副本及合成示例完成真机复测；正式 TestFlight build 4 尚未重新安装到真机验证。项目独立准确度、监管适用性与完整真实 HealthKit 证据仍分别记录，不把测试或 Apple 接收提交等同于这些证据完成。下文 2026-10-11 部分保留为 build 3 的历史提交记录。

## 2026-10-11 公开 Beta 状态与资料要求

外部群组 **PB** 已加入 0.6.0（3），提交 Beta 审核并启用自动通知。公开链接为 https://testflight.apple.com/join/qXWxxJev ，向所有人开放；Connect 明示群组内尚无已批准构建，因此目前不能加入。六语 Beta 描述、用户提供的真实反馈邮箱与审核联系人、无需登录、方法/隐私网址及审核备注已保存。

此前四项是项目证据门槛，不是 Apple 统一规定必须上传的四张证书。Apple TestFlight 必填的是 Beta 描述、反馈邮箱、审核联系信息、测试内容及必要的登录信息。真机全流程和邮件投递没有固定报告上传入口，但仍需保证应用与联系渠道正常工作。健康测量数据/方法按 1.4.1 披露；医疗器械许可只在实际适用或已获得许可时提供链接。健康领域主体资格按 5.1.1(ix) 与实际功能判断，健康健美类别和免责声明不能代替这些要求。

用户现要求直接推进公开 Beta。本轮完成表单和 Beta 提交，暂不扩大到独立准确度、监管审查或额外真机/邮箱测试；`readiness.json` 仍如实保留未完成证据，不能把 Apple 已接收提交解释为就绪或批准。若 Apple 需要补充方法、准确度或许可资料，在 Beta 审核备注提供链接，并通过审核消息回复具体要求。

资料来源：[测试信息](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)、[外部测试与公开链接](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)、[审核指南 1.4.1、2.2、5.1.1](https://developer.apple.com/app-store/review/guidelines/)，2026-10-11 在线核实。

## 项目既有证据缺口

- **实际功能与主体资格**：保留自动分段、HRV、早搏候选和节律参考分；Apple 1.4.1 的方法与准确度证据、5.1.1(ix) 的敏感信息/高度监管服务法律实体要求仍须按实际功能核对。用户授权个人团队不等于已满足 Apple 健康领域主体资格要求；须按实际功能核对当前主体适用性。
- **政策与支持**：中英正式隐私政策、条款和支持页面已部署到 `heartpro.alkinum.com` 并通过公开 HTTPS 验证，可使用准备材料中的 URL。支持邮箱 `support@heartpro.alkinum.com` 的收信配置和实际投递仍待验证；网站可访问不证明邮箱可收信。
- **产品验证**：真实 Apple Watch 独立准确度证据、真机 HealthKit 授权/拒绝/撤销/写症状/清空等仍未完成。示例、单元测试和免责声明不能代替这些证据。使用[真机表](validation/device-checklist.md)和[准确度方案](validation/watch-accuracy-protocol.md)。
- **Beta 联系资料**：准备真实联系人姓名、邮箱、电话；测试说明和反馈邮箱。没有账号登录，无需测试账号。用户已提供真实联系人，App Store 审核联系资料已保存；外部 TestFlight 表单已在本轮填写并保存。不能用占位文字填入后台；英文审核说明已整理，但不表示其他审核证据已齐。

Apple 的 2.2 明确规定，TestFlight 分发也必须符合 App Review Guidelines。先在本机/受控设备完成开发验证；缺项未补齐时不要把“处理成功”的构建当成“已获准外测”。

## 1. 配置开发者账号和 App ID

1. 使用有效的付费 Apple Developer Program 账号，在 Xcode → **Settings → Accounts** 添加 Apple Account。
2. 在 Apple Developer → **Certificates, Identifiers & Profiles → Identifiers** 注册明确 App ID：`com.alkinum.heartpro`，启用 **HealthKit**。不要选旧 `app.heartpro.ios`，也不要注册通配符 ID。
3. 进入 App Store Connect → **My Apps → ＋ → New App**：平台 iOS；当前公开名称 HeartPro；主要语言 English；选择上述 Bundle ID；SKU 可用 `heartpro-ios`。名称占用时调整商店名称，保持项目与 App ID 一致。
4. 在账户界面完成你应亲自接受的协议及需要补齐的资料。付费下载的税务/银行安排与当前无 IAP 的实现分开处理。

## 2. 在 Xcode 配置项目

直接打开仓库中的 `HeartPro.xcodeproj`，无需先打开 workspace。

1. 选择 **TARGETS → HeartPro → Signing & Capabilities**，开启 **Automatically manage signing**，选择正确 Team，确认 Bundle Identifier 为 `com.alkinum.heartpro`，有 HealthKit capability。
2. 不要添加当前没有使用的 iCloud、HealthKit Background Delivery、Clinical Health Records 或 Push Notifications 权限。
   当前源码和 0.6.0（3）分发签名已完成 [entitlement 审计](validation/entitlements-2026-10-12.md)。运行 `rtk proxy python3 Tools/check_entitlements.py` 检查声明；每次导出后使用 `--app '/absolute/path/Payload/HeartPro.app'` 核对实际分发签名。默认分发模式必须拒绝 `get-task-allow=true`，开发 xcarchive 的权限不能代替上传重签名结果。
3. **General → Identity**：Version 当前为 `0.6.0`；Build 当前为 `4`，已经上传。下一次 Archive 前递增，如 `5`。版本号允许保持 `0.6.0` 用于 TestFlight，不必为了上传改为 `1.0.0`。
4. 工程由 XcodeGen 生成。版本和构建号的持久来源是根目录 `project.yml` 的 `MARKETING_VERSION`、`CURRENT_PROJECT_VERSION`；若只改 Xcode，之后运行 `xcodegen generate` 会覆盖这些改动。重新生成后复核 Team。
5. Scheme 选择 **HeartPro**。**Product → Scheme → Edit Scheme → Archive** 的 Build Configuration 应为 **Release**。运行参数中的 `--demo`、`--uitesting` 等只用于开发运行；审核员可以通过真实的“先看看示例”入口体验，不依赖参数。

2026-09-22 的工具链记录为 Xcode 27.0（27A266a）与 iOS 27 SDK。提交前重新核对本机版本，使用 Apple 当前接受上传的 Xcode/SDK；本地编译成功不能证明 Connect 接受。

## 3. 先运行与检查

在真机 Run，检查首次出现独立的使用须知、确认后进入指南、设置可重看、示例不要求健康授权。随后按真机表检查真实数据流程。

可在项目根目录运行本地检查：

```sh
rtk proxy python3 Tools/localization.py --check
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy python3 Tools/check_appstore.py
rtk proxy python3 Tools/check_appstore.py --external-testflight
```

最后一条在当前状态会失败并列出证据缺项，这是正确结果。不要通过把 `readiness.json` 改成 `true` 代替真实验证。正式 App Store 材料门槛用 `--submission`，还包括截图等商店资料。

## 4. Archive 与上传

1. Xcode 顶部运行目标选择 **Any iOS Device (arm64)** 或对应的通用 iOS 设备，不能选择模拟器。
2. 菜单 **Product → Archive**。完成后打开 **Window → Organizer → Archives**，选中正确版本。
3. 检查归档中的 Bundle ID、版本、Build 和 Team。使用 Organizer 的 **Generate Privacy Report**（如当前版本提供）核对隐私清单：自身容器时间戳 `C617.1`、UserDefaults `CA92.1`，没有跟踪或新增采集 SDK。
4. 运行 **Validate App**（若当前分发界面没有独立按钮，上传流程也会进行验证），修复实际签名、权限、资源或 SDK 报错。
5. 点击 **Distribute App**，选择 **App Store Connect / TestFlight & App Store → Upload**，使用自动签名，并检查上传摘要。**不要选 TestFlight Internal Only**：该构建不能分配给外部测试组。
6. 完成上传后，在 App Store Connect → HeartPro → **TestFlight → iOS Builds** 等待 Processing 完成。构建未出现时查看 Organizer 交付日志和 Apple 的处理邮件，不要反复上传同一构建号。
7. 处理 **Missing Compliance** 等状态。当前 `ITSAppUsesNonExemptEncryption = NO` 基于只使用平台保护、没有自有非豁免加密；按最终二进制如实回答。增加网络或加密功能后需重新评估。

九月历史本地 archive 使用 `CODE_SIGNING_ALLOWED=NO`，只验证 Release 打包，**不能直接作为已签名的分发归档上传**。请按以上步骤用你的 Team 重新 Archive。

## 5. 配置外部测试并提交 Beta App Review

1. TestFlight 中先创建一个 **Internal Testing** 组（Apple 当前文档要求先有内部组，才能创建外部组）；内部测试者是具有访问权限的 App Store Connect 用户。不要为普通外部测试者添加后台账号。
2. 创建 **External Testing** 组，例如 `Early testers`，为该组添加处理完成且不是 Internal Only 的构建。
3. 在 Test Information / Beta App Review Information 中填写 Beta App Description（`testflight/beta-description.<locale>.txt`，六语）、Feedback Email、实际审核联系人、Review Notes；如当前表单要求 Privacy Policy URL，使用已定稿且可访问的链接。无需账号登录时不提供虚构账号。
4. **What to Test** 使用[中文测试说明](testflight/what-to-test.zh-Hans.txt)、[英文版](testflight/what-to-test.en-US.txt)或同目录的日/韩/德/西语。本轮已增加窄 QRS 标签、0.5 倍缩放、大字号、深浅色与全屏检查。请测试者关注展示、权限、数据同步、测量可用性与导出，不把测试当成医学判断或临床试验。
5. 将所有实际功能写进 Review Notes，包括早搏候选和节律分、局部估算的未验证边界、可选症状写入；说明首次使用须知及示例路径。不要隐去分析功能，也不要声称已获得监管许可或未经核验的主体资格。
6. 补齐上述审核前缺项后点击 **Submit for Review**。首个外部构建需要完整 Beta App Review；后续同版本构建也可能需要审核，不能保证即时通过。
7. 获批后手动 **Start Testing / Notify Testers**，通过邮箱邀请或启用公开邀请链接。先用少量受控邀请验证安装和支持流程；公开链接可设置人数上限及设备/系统条件。当前外部测试上限为每个 App 10,000 人，构建通常自上传起可测试 90 天，以控制台显示的到期日为准。

TestFlight 会由 Apple 处理安装、会话、崩溃及测试反馈信息。当前应用不主动向开发者服务器上传健康记录，并不意味着 TestFlight 没有测试信息。避免收集带个人 ECG 的反馈截图；通过 TestFlight 提交内容前由测试者自行检查。

## 6. 尽量多地区的安排

TestFlight 邀请与正式 App Store 的 **Pricing and Availability → Countries or Regions** 是不同的分发设置。外测获批不代表已向全球正式上架，也不代表 Apple Watch ECG 在每个地区都可用。

正式发布时逐地区确认：实际软件用途和医疗器械规则是否适用、敏感健康数据与支持邮件的隐私要求、商店允许的地区、消费者规则；欧盟另核对 DSA trader 身份及适用的 GDPR/MDR 问题，中国大陆核对该产品实际适用的 App 备案、健康数据及医疗软件要求。不能因为数据本地处理或加入免责声明，就一律认定这些要求不适用。完成适用性审查的地区再开放，后续逐步增加。

## 常见卡点

| 情况 | 处理 |
| --- | --- |
| Archive 灰色 | 选择 HeartPro scheme 和通用 iOS 真机目标 |
| No profiles / HealthKit entitlement 不匹配 | 核对 Team、明确 App ID 的 HealthKit、自动签名及新 profile；不要删除权限来绕过签名 |
| Build already exists | 在 `project.yml` 递增 Build，重新生成工程、检查 Team、重新 Archive |
| 外部组看不到构建 | 检查是否 Processing、Missing Compliance、Internal Only，及该构建是否符合组的条件 |
| 1.4.1 或 5.1.1(ix) 问题 | 如实补充方法、验证和主体资格；免责声明不是自动豁免 |
| 网站打不开或政策仍是草稿 | 先完成定稿、HTTPS 发布和支持邮箱验证，再提交 |

## 本次在线核对的 Apple 文档

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：1.4.1、2.2、5.1.1(ix)、5.1.3。
- [邀请外部测试者](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)：内部组前置、Internal Only 限制和首次审核。
- [上传构建](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)：构建处理及工具链要求。
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)：本机处理与 collected 的区别。
- [更新开发者账号资料](https://developer.apple.com/help/account/membership/updating-your-account-information/)：个人转组织需符合组织资格并向 Apple 申请。

九月网页核对快照和历史测试记录见 [evidence/testflight-2026-09-22](evidence/testflight-2026-09-22/)。
