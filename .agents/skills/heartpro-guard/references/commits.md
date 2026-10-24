# HeartPro 提交规范

## 信息格式

采用 Conventional Commits：

```text
type(scope): 描述具体变化

必要时解释动机、行为变化和验证结果；未运行的检查说明原因。
```

- type 必须为 `feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert` 之一。
- scope 可省略；优先用 `app`、`core`、`healthkit`、`ui`、`report`、`l10n`、`website`、`appstore`、`guard` 等实际领域。使用小写字母、数字，允许中间的 `-`、`.`、`/`；不限定为封闭列表。
- 标题最多 100 个 Unicode 字符，冒号后恰好一个空格，描述不能为空，末尾不加句号；中英文均可。英文用动作表达；避免 `update`、`fix stuff` 等无法说明变化的信息。
- 正文与标题之间空一行。重大不兼容变化使用 `!`，并附 `BREAKING CHANGE: 影响及迁移说明`；没有 `!` 时也可以使用该 footer。
- `style` 仅用于不改变行为的格式调整；可见 UI 修复用 `fix(ui)`，新增交互用 `feat(ui)`。
- 整理后才共享 `fixup!` / `squash!` / WIP 提交。真正的多父 merge commit 可保留 Git 生成的 `Merge …` 标题；手写同名普通提交不豁免。Git 默认的 `Revert "…"` 需改为 `revert(scope): …`。
- 本规范从建立 guard 后的新提交生效。`534d6831feb8c63ab6b5f213675d455747bc622b` 及其祖先作为历史基线，不追溯改写。已推送历史只能在用户明确授权历史改写后处理。

示例：

```text
feat(ui): add a first-use notice before loading records
fix(core): preserve missing intervals during HRV analysis
docs(appstore): 完善六语审核材料
chore(guard): enforce development, design, and commit standards
```

## 文件卫生与检查

1. 先看 `git status --short --ignored` 和 diff；暂存前确认 `.gitignore` 覆盖编译缓存、测试结果包、本地环境和签名材料。检查已跟踪文件：忽略规则不会自动把它们从索引移除。
2. 优先按本次范围暂存；用户要求提交全部现有内容时，审阅后可 `git add -A`。不使用 `git add -f` 夹带构建产物或凭据。若确实要版本管理一个文件，应先收窄对应忽略规则并说明用途。
3. 从根目录运行 `rtk proxy python3 Tools/guard.py staged`，检查暂存区空白、常见凭据模式及整个索引中命中忽略规则的文件。`.gitignore` 有改动时先暂存，以保证检查使用的规则与提交一致。脚本只报告可疑文件路径，不打印密钥；对文本/日志另行检查个人健康信息，它不是完整的内容泄漏扫描器。
4. 审阅 `git diff --cached`，确认检查结果对应最终提交内容，再提交。相关验证失败必须修复或如实说明；不得用 `--no-verify` 掩盖格式或文件卫生失败。
5. 推送后确认本地/远端提交一致；只有在当前任务授权时才提交/推送，不因调用 skill 自动获得发布权限。

发布资料和本机配置在公开仓库之外维护，不纳入公开提交。凭据、签名材料、构建产物、空白和提交格式按上述流程检查；历史改写需要单独明确授权。

## 启用与复用

```sh
rtk proxy python3 Tools/install_hooks.py
rtk proxy python3 Tools/guard.py staged
rtk proxy python3 Tools/guard.py message --file /tmp/heartpro-commit-message.txt
rtk proxy python3 Tools/guard.py commits --range BASE..HEAD
```

安装器只设置当前仓库的 `core.hooksPath=.githooks`；如已有自定义 hook 路径或有效原生 hook，会保留它并报告冲突，先集成再安装。`pre-commit` 检查暂存内容，`commit-msg` 检查信息；每个新克隆需安装一次。

`.github/workflows/guard.yml` 在 push/PR 检查新增提交信息、最终受跟踪文件与 guard 自身行为测试。CI 不依赖本机 hook，也不声称完成原生 UI/算法验证。GitHub 分支保护是远端设置，新增 workflow 本身不等于已启用禁止合并规则。
