# 审核附件与证据清单

审核备注已提供正常首启和示例操作路径。下面的附件用于解释功能，不要将文件数量当成验证结论，也不要在其中放入个人健康记录。

| 内容 | 当前文件 / 状态 | 用途 |
| --- | --- | --- |
| 首次使用须知 | `../evidence/usage-notice-design-2026-09-22/zh-usage-notice.png`、`language-contact-sheet.jpg` | 展示能力边界、就医提醒、全用户一致的确认流程 |
| 六语功能界面 | `../screenshots/iphone-6.9/`、`../screenshots/ipad-13/` | 展示原生页面、合成数据标识和完整功能；无需全数重复作为审核附件 |
| 英文示例 PDF | `../evidence/testflight-2026-09-22/report-en.pdf` | 若审核员需要，可展示实际导出结构、波形、备忘和边界提醒；使用合成数据 |
| 其他语种示例 PDF | 同目录 `report-zh-Hans.pdf`、`report-ja.pdf`、`report-ko.pdf`、`report-de.pdf`、`report-es.pdf` | 同上；导出代码未在本轮材料整理中修改 |
| 方法介绍 | `https://heartpro.alkinum.com/docs/methods/` | 需要先发布为可访问的正式页面；本地内容源见网站 docs/methods |
| 真实 Watch 独立准确度 | 尚缺；执行方案 `../validation/watch-accuracy-protocol.md` | 完成后附真实报告，包含冻结版本、合法数据来源、参考真值、覆盖率、误差/置信区间和失败案例 |
| 真机权限与删除验收 | 尚缺；`../validation/device-checklist.md` | 真实授权、拒绝、撤销、症状写入、清空与重启流程 |
| 法规/主体/地区结论 | 尚缺 | 仅提供真实可核验材料；不能把免责声明或个人账号证明写成医疗资格证明 |

本轮两组各六项截图流程通过；测试摘要位于 `../evidence/submission-materials-2026-09-22/iphone-tests-summary.json` 和 `ipad-tests-summary.json`。测试在模拟器和合成示例运行，不证明真实 HealthKit 数据读取、医学准确度或生产签名。

按用户指令，本轮只准备材料，未向 Apple 提交附件、发送支持邮件或邀请测试者。
