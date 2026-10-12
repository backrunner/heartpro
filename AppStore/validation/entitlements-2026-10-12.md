# HeartPro entitlement 审计

核对日期：2026-10-12。对象：当前源码与上传流程保留的 **0.6.0（3）** 分发包，Bundle ID `com.alkinum.heartpro`。

## 结论：通过

当前源码只声明 `com.apple.developer.healthkit=true`。这是读取 ECG、心率、HRV，以及用户主动选择症状写回 Apple 健康所必需的能力。首次健康授权只读上述三类数据；症状写权限按用户选择单独申请。没有 ECG 写入、症状历史读取或临床病历读取。

没有声明 HealthKit Background Delivery、Clinical Health Records、iCloud/CloudKit、Push Notifications、App Groups、Associated Domains 等额外能力。Info.plist 只有实际使用的健康读取和写入说明，没有后台模式或后台任务标识；SwiftData 明确使用 `cloudKitDatabase: .none`。

源码没有发现需要删除的 entitlement，因此保持功能配置不变。

## 分发签名：通过

直接检查 Xcode 上传流程保留的 `XcodeDistPipeline.~~~swBfA1/Root/Payload/HeartPro.app`，并与同一流程的 `Packages/HeartPro.ipa` 比对：包内 22 个 app 文件与检查对象逐字节一致。`codesign --verify --deep --strict` 成功；签名权限与内嵌 provisioning profile 相容。

| 实际签名键 | 值 | 用途 |
| --- | --- | --- |
| `com.apple.developer.healthkit` | `true` | 现有健康功能 |
| `application-identifier` | `PB8H83VL3Z.com.alkinum.heartpro` | 签名应用标识 |
| `com.apple.developer.team-identifier` | `PB8H83VL3Z` | 签名团队标识 |
| `get-task-allow` | `false` | 分发包禁止调试附加 |
| `beta-reports-active` | `true` | App Store/TestFlight 分发配置 |

没有 Keychain 共享权限或额外签名权限。Apple 的 [TN2319](https://developer.apple.com/library/archive/technotes/tn2319/) 区分开发/分发的 `get-task-allow`，并说明 App Store profile 的 `beta-reports-active`；这些签名元数据不应被当成未使用的产品能力删除。

分发 IPA SHA-256：`c997d21fedb4d02100c82193f392aa2092275932ead165949e9dc10e1004462c`。

应用主可执行文件 SHA-256：`a44d1b974071a58e919bd7815036b168389c331a5f01759925e3bf27e9a77d66`。

开发签名的原始 xcarchive 含 `get-task-allow=true`，符合开发用途。上传重签名已将其改为 `false`；开发归档不能代替最终分发包的检查。

## 后续防回归

`Tools/check_entitlements.py` 默认核对源 entitlement 白名单、XcodeGen/生成工程路径、权限说明及后台配置；`Tools/check_appstore.py` 和 CI guard 已调用此检查。新增任何 entitlement 都必须更新审计依据。

对每次导出的真实分发 app 另行运行：

```sh
rtk proxy python3 Tools/check_entitlements.py
rtk proxy python3 Tools/check_entitlements.py --app '/absolute/path/Payload/HeartPro.app'
rtk proxy python3 -m unittest discover -s Tools/tests -p 'test_entitlements.py'
```

`--app` 默认要求 App Store/TestFlight 签名、检查最终 Info.plist、签名和 profile 相容性，并拒绝未经审计的新嵌入可执行 bundle。开发包必须显式使用 `--development`；不能用该选项替代分发验收。profile 可能允许比实际签名更多的能力，审计以实际签名为准。

验证：源检查、实际分发 app、开发归档显式开发模式、12 项回归测试和本地材料检查均通过；开发归档在默认分发模式下被正确拒绝。CI 配置已补充，但本轮没有推送或取得远端运行结果。

`git diff --check` 通过。通用 `Tools/guard.py tracked` 因工作区既有 `.gitignore` 修改尚未暂存而拒绝执行；本轮保留原有暂存状态，没有将其标记为通过。

此结果仅覆盖 entitlement/相关权限声明，不代表真机 HealthKit 全流程、其他审核条件或 Apple 审核已通过。临时分发目录可能被系统清理；下一构建需检查其自身签名。
