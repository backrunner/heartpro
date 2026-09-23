# HeartPro 开发规范

## 模块与数据边界

- `Packages/HeartProCore` 保持纯 Swift：领域模型、信号处理、统计与合成夹具不依赖 SwiftUI、HealthKit、SwiftData 或网络。相同输入和配置产生相同分析结果。
- `HeartPro/Data` 负责 HealthKit、存储、同步与报告；`App` 组织生命周期和状态；`Features` 呈现功能；`Design` 提供共用视觉与波形组件。延续现有模块，不为小变化增加无用途的服务或 package。
- Swift 6 严格并发保持开启。UI 状态在正确隔离域更新；数据库、全长波形、JSON 和分析工作不阻塞主线程。异步结果提交前核对记录 revision/任务 generation，取消不能让旧任务覆盖新状态。
- 列表只取轻量摘要，详情按需读完整分析；分页按日期和 UUID 稳定排序。时间边界用 Calendar，避免把一天固定为 86,400 秒。
- 保留原始波形及可追溯采样坐标。显示降采样不参与测量；缺口不插值伪装连续。无法测量时保留空值和具体原因，不能补零或演示值。
- 分析计算或接受条件改变时，核对算法版本、旧记录解码和重分析路径；纯显示文字更新不触发无关重分析。数据迁移不能丢失备忘，来源删除和晚到分析不能使数据复活。

## 权限、隐私与能力

- Apple ECG 只读。用户明确选择的症状才请求写入权限并写为独立样本；算法候选、演示记录和自由文本不得冒充健康样本。写回失败保留本地备忘，重试需幂等。
- HealthKit 查询为空不证明拒绝授权，也不证明历史已删除。读取错误、无数据和等待状态分别处理。
- 默认本地处理，维持文件保护、排除备份、后台遮挡和 CloudKit 关闭。示例使用独立内存数据，不混入真实记录。日志和仓库不得包含个人健康数据、私钥或令牌。
- 首次使用须知确认前，不加载记录或启动健康同步；设置可重看。`--uitesting` 等测试参数不能在普通运行中绕过首次说明。
- Apple 来源分类、合成分类、本地估计和用户记录分别标识。参考分不等于健康分或风险概率；不按个人数值输出病因、用药建议或疾病诊断。
- 公共 Holter 基准、合成测试、免责声明都不能证明真实 Apple Watch 准确度。发布状态按当前证据填写，普通开发不擅自修改就绪门槛。

## 源文件与生成物

- 项目配置以 `project.yml` 为源；需要时运行 `rtk proxy xcodegen generate`，同时审阅 `HeartPro.xcodeproj` 的生成差异，避免只改生成项目而丢失配置。
- 六语显示内容通过 `Localization/` 源文件和 `HeartProCore.L10n` 维护。保留稳定的持久化标识、插值占位符、用户文字及 HealthKit 来源；修改翻译后生成并检查，详见 `Localization/README.md`。
- 截图、图标、报告示例等有明确用途的产物可以版本管理，记录其来源与版本；编译缓存、临时导出、安装包和个人数据应排除。不要用全局 `*.png`、`*.pdf`、`*.log` 忽略规则破坏已有验证材料。

## 按影响选择验证

| 变化 | 最小相关验证 |
| --- | --- |
| 核心计算、阈值、版本 | `rtk proxy swift test --package-path Packages/HeartProCore`；补充实际失败、边界、拒绝条件回归，必要时执行已有数据审计 |
| HealthKit、持久化、同步 | 相关 App 测试及构建；权限/写回验收需要真机证据，模拟器结果单列 |
| 原生界面、报告 | 相关 UI/ReportTests 和实际截图/PDF检查；范围见设计规范 |
| 本地化 | `rtk proxy python3 Tools/localization.py --check`；涉及布局时检查长译文与大字号 |
| Xcode 配置/新 Swift 文件 | XcodeGen 后构建目标，审阅生成 diff |
| 网站 | 在 `website` 下按影响运行 `rtk proxy pnpm check`、`check:docs`、`build`、`test`；dev 与 build 不并行 |
| App Store 材料 | `rtk proxy python3 Tools/check_appstore.py`；分发请求才加相应发布参数 |
| Guard/hook | `rtk proxy python3 -m unittest discover -s Tools/tests -p 'test_guard.py'`，检查真实 hook 接受/拒绝行为 |
| 纯规范文档 | 校对引用与当前实现、`git diff --check`；不要求重跑无关产品测试 |

原生测试命令依据 README，先从可用模拟器选择实际目的地；可以用 `-only-testing:` 缩小到受影响测试。保留本仓库的 `-parallel-testing-enabled NO -collect-test-diagnostics never`。新增测试验证行为或关键不变量，不镜像实现、不只锁定文案或样式字面值。

记录命令、结果、运行环境和未验证范围；构建、安装、启动、视觉验收分别说明。执行受阻可完成可行检查并提交如实标注的开发检查点，不能宣称验收完成。
