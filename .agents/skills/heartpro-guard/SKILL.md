---
name: heartpro-guard
description: Guard development, UI and report design, validation evidence, Git hygiene, and commit messages in the HeartPro Swift app and its companion website. Use when implementing, reviewing, preparing commits, or releasing HeartPro changes; unrelated repositories are outside its scope.
---

# HeartPro Guard

让 HeartPro 的实现、设计、验证结论和提交保持一致。此 skill 随仓库版本管理；命令从仓库根目录运行。先确认当前目录包含 `project.yml`、`HeartPro/` 和 `Packages/HeartProCore/`。

## 按任务读取

- 实现或评审代码：读 [开发规范](references/development.md)。
- 改 UI、交互、文案、图表、PDF 或网站：同时读 [设计规范](references/design.md)。
- 暂存、提交、推送或检查 Git：读 [提交规范](references/commits.md)。
- 上架或外部测试：另外读 `AppStore/readiness.json` 和 `AppStore/testflight-guide.zh-CN.md`。普通开发不运行发布门槛，也不因发布证据尚缺而停止本地工作。

## 工作流程

1. 查看 `git status`、相关 diff 和当前实现；保留已有工作。历史 `.agents` 规划不能直接视为当前实现或验证证据。当前规范和最新明确需求优先于历史目标；新需求改变约定时，同步修改相应规范。
2. 按本次变化选择检查。数据、算法和权限必须核查不变量；界面必须核查实际呈现；仅文档或工具变化不要求完整 iOS 回归。能在已授权范围内修正的问题直接修正。
3. 对结果使用 **通过 / 待验证 / 不适用**，不能用脚本成功替代设计验收。发现明确违规时，说明文件、影响和修正；缺少环境证据时，标明缺口并继续独立工作。不得为了通过检查删除已有能力、降低验证门槛或伪造证据。
4. 提交前运行 `rtk proxy python3 Tools/guard.py staged`，审阅暂存 diff，并按提交规范拟定信息。自动检查覆盖 Git 文件卫生、常见凭据模式、空白和提交格式；架构、视觉与医学表述仍需人工/agent 判断。
5. 完成时简述变化、已运行的检查和未验证项；提交/推送仅沿用当前任务授权，skill 本身不授予外部操作权限。

## 本地维护资料

账户截图、原始账户页面和开源历史维护记录遵循 `.gitignore`，只保留在本地，不作为公开提交内容。用户已结束旧 GitHub 对象的清理事项；除非用户另行明确要求，后续开发、提交、CI 和本 skill 不复查其姓名、截图、OCR 或旧 SHA，不生成新的公开审计记录，也不将其列为待办或发布门槛。

采用本仓库的 RTK shell 约定。项目安装命令：`rtk proxy python3 Tools/install_hooks.py`；新克隆需要执行一次。Git hook 和 CI 内部直接调用 Python/Git，不要求 CI 安装 RTK。
