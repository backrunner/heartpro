# HeartPro

原生 Swift 心脏健康与心电记录应用。使用 SwiftUI、HealthKit、SwiftData、Swift Charts 和 Canvas；iOS 26+ 使用原生 Liquid Glass，iOS 18–25 回退到系统材质。

## 运行

开发、设计与提交统一遵循 [HeartPro Guard](.agents/skills/heartpro-guard/SKILL.md)。首次克隆先运行 `rtk proxy python3 Tools/install_hooks.py`，启用暂存内容和 Conventional Commits 信息校验。

要求：Xcode 26+、iOS 18+ SDK 和 XcodeGen。当前开发环境为 Xcode 27 / Swift 6.4。

```sh
rtk proxy xcodegen generate
rtk proxy open HeartPro.xcodeproj
```

选择 HeartPro scheme 和 iPhone 模拟器运行。首次打开可阅读使用指南，之后点击「先体验示例」可浏览明确标记的合成数据；正常启动不会自动生成个人健康数据。也可在 Run scheme 的 Arguments 中添加 `--demo`。`--uitesting` 使用内存数据库供 UI 测试使用。`--skip-guide` 跳过指南；`--reset-guide` 仅在 UI 测试模式重置指南状态。

真机运行需要在 Signing & Capabilities 中选择自己的 Apple Developer Team，并为 `com.alkinum.heartpro` 配置 HealthKit。默认不申请后台 ECG 交付权限；前台启动／回到前台／手动刷新完成增量同步。

## 已实现

- 两个主入口：心电历史、当日／趋势；备忘在每条 ECG 详情内新增、编辑和删除。统一原生玻璃导航与控件、纸质心电网格。
- 当日概览、连续历史分页、日历与左右切日、日／周／月／年图表。
- 完整心电横向浏览、双轴等比例缩放、固定左侧 mV 刻度、Apple 健康式系统红波形、双点手动测量、R 峰显示、事件定位、PDF 导出。
- HealthKit 最近样本与全历史 anchored 导入、持久化 anchor、删除传播、待处理队列与中断恢复。
- SwiftData 元信息／结果／备忘存储；波形二进制文件与 256 MiB 可再生缓存预算。
- 研究性质量检查、正反向 R 峰、RR 统计、相邻 RR 散点、短—长组合、振幅及局部形态离群点；纯 Swift 核心及独立测试。
- P、PR 间期、PR 段、QRS（含 Q／R／S 分量）、ST／J、T、QT、QTc、TP、RR／PP 的逐搏研究估计；逐项覆盖、中位数／范围／P10–P90、缺失原因、逐搏分布与原波形定位；PDF 包含已支持分段的完整统计。U 波模块仅在检出足够重复候选时显示。
- 随 ECG 保存的本地备忘、快捷症状、发生时间／持续时间／程度；用户选择后将受支持症状作为 HeartPro 独立记录写入健康；失败保留本地记录并可手动重试。
- 首次连接一次请求日常心率、ECG 和 HRV 读取；每日心脏健康概览保留按小时心率范围。趋势按日查看近 14 天、按周查看近 13 周、按月查看近 12 个月。日期选择器下方整页支持左右滑动：每日页切换一天，趋势页切换完整窗口；日常心率与 Apple 健康 SDNN 上下平铺，共用日期范围，点按各自图表查看汇总值。健康 SDNN 与单次 ECG 的 HRV 估算分开展示。
- 0.6.0：详情页精简说明、居中 HRV 聚集图；原始心电支持横屏全屏和顶部实测波段／间隔标注。修复快心率基线窗口倒置与慢漂移误判噪声的问题；旧记录按新版本重分析。[算法与边界](.agents/segment-analysis.md)。
- 0.5.3：首页移除普通心跳差异提示，突出 Apple 分类中的高/低心率及房颤信息。
- 0.5.2：首次连接页与教学引导采用原生 Liquid Glass 操作按钮，欢迎页精简文案、底部固定连接入口。[设计与验证](.agents/landing-0.5.2.md)。
- 0.5.1：首次使用指南和设置重看、卡片右上角入口、精简文案；30秒 HRV 使用所有合格间隔，相邻统计不跨缺口。
- 0.5.0：系统复用历史列表、轻量摘要与后台仓库、日历直达旧日期、精简记录卡片；分段参考区间与偏离解释，以及经过间隔筛选的 SDNN／RMSSD 和 Poincaré 聚集图。[设计与边界](.agents/heart-health-0.5.md)。
- 0.4.0 新增早搏候选的时序／波形联合检测、可定位的逐搏依据及节律参考分；分数表示未被本轮规则标记的心跳比例。U 波仅在清楚分离、重复出现的候选足够时显示。规则与验证边界见 [节律分析说明](.agents/rhythm-analysis.md)。
- 设备文件保护、备份排除、后台快照遮挡、清空本地数据；没有分析服务器、账号或健康数据遥测。


## 语言

支持简体中文、英语、日语、韩语、德语和西班牙语，跟随 iOS 的 App 语言设置；应用「设置 → 语言」可打开系统设置更改。界面、分析解释、图表、权限提示及 PDF 共用语言资源，日期与数字按所选语言格式显示。

「未测得」已按情境改为「暂时无法测量」或「等待分析」，并保留具体原因。未实现的功能从界面与报告中隐藏。切换语言不需要重新分析；算法版本升级会排队重新分析。用户备忘与 HealthKit 来源名称保留原文。资源维护与验证见 [多语言说明](Localization/README.md)。

## 当前能力边界

本轮逐项覆盖和实质缺口见[功能核对](.agents/feature-audit.md)。不能将合成演示或不可评估说明视为完成了自动医学分析。

这是开发预览，不是医学产品或完成临床验证的分析器。研究性检测尚未经过真实 Watch 独立标注验证。低质量、边界不清、重叠或研究窗口外不输出对应数值；参考区间仅帮助理解数值，不根据这些数值诊断正常／异常。0.4.0 的早搏候选做了合成波形与八条公开 MIT-BIH 记录对照，复杂节律仍有明显漏检。宽窄分类不确认房性／室性起源，节律参考分不是健康分。固定演示分已移除；目前不提供评分趋势。0.5 提供明确标注为超短时研究估算的 ECG HRV，筛选不能确认正常心搏，也不能等同标准5分钟HRV。

Apple ECG 始终只读。症状写回不能修改 Apple ECG 备注。已写回的症状在当前版本中保留不可变，本地文字仍可编辑；外部症状的编辑／删除由健康 App 管理，避免误改已导出的内容。备忘中的本地删除不连带删除健康样本。

单导联不能可靠识别或排除心梗、心肌缺血。所有分析仅供参考，不能用于医疗用途，不能替代医生诊断。

## 验证

0.5.1：44 项核心测试、643 个六语键检查、真机签名构建与模拟器测试构建通过；已安装并启动至用户 iPhone。应用/UI测试运行仍卡在模拟器启动阶段。[验证记录](.agents/validation/usability-0.5.1/README.md)。

0.5.0：42 项核心测试、602 个六语键检查、arm64/x86_64 模拟器测试构建通过。应用及 UI 测试因模拟器启动/应用启动停滞未得到运行结果；真机授权与长历史滚动性能仍待验证。[本轮验证记录](.agents/validation/heart-health-0.5/README.md)。

报告排版与圆形信息按钮：4 项报告测试、3 项相关 UI 用例通过，六语资源 543 个键检查通过。[查看 PDF、界面截图及验证范围](.agents/validation/report-design-0.4/README.md)。

报告主题已统一为应用珊瑚红，4 项报告测试复测通过。[查看当前报告](.agents/validation/report-theme-0.4/README.md)。

```sh
rtk proxy swift test --package-path Packages/HeartProCore
rtk proxy xcodebuild -project HeartPro.xcodeproj -scheme HeartPro \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO test
```

0.4.0：35 项核心测试、7 项 App 测试和 5 项相关 UI 测试通过，包含六语流程与德语大字号候选页面；512 个语言键检查通过。八条公开记录的早搏总体检出率为 43.78%，复杂节律仍明显漏检，不能作为可靠筛查功能。[查看规则、数据审计与截图](.agents/validation/rhythm-0.4/README.md)。

0.3.0：24 项核心测试通过；最终 6 项 App 定向测试通过，另外 4 项原有 UI 用例在本轮全量运行中通过。[查看逐段分析验证与截图](.agents/validation/segments-0.3/README.md)。

0.2.0 检查：12 项核心测试通过；9 个 App 测试用例均已有通过结果（完整运行及定向复测）。[查看新版验证记录与截图](.agents/validation/refinement-0.2/README.md)。本环境的 iOS 27 测试诊断收集曾停滞，因此命令关闭额外诊断收集，断言、截图与 xcresult 仍保留。

测试区分纯数值、存储和模拟器 UI；模拟器不能证明真实 HealthKit 历史接入、写回或临床准确度。进度与已知限制见 [.agents](.agents/README.md)。0.3.0 的逐段定义、算法窗口与验证记录见 [逐段分析说明](.agents/segment-analysis.md)。

App 图标采用「心电刻印」设计：完整红色心形内嵌留白心电线，提供浅色、深色两种外观。由 Swift 绘制，无外部图片依赖；下面的命令同时导出 `AppIcon.png` 和 `AppIconDark.png`：

```sh
rtk proxy swift Tools/GenerateIcon.swift HeartPro/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## App Store 准备

外部测试请按[本项目 Xcode → TestFlight 指引](AppStore/testflight-guide.zh-CN.md)操作。当前新增首次使用须知（先确认再进入指南/健康同步，设置可重看），保留分析能力，同时移除根据个人测量解释病因或用药的输出；Apple 来源分类明确标识。提醒不代表已通过医疗用途、个人主体或全球分发的审查。[本轮验证与未完成事项](AppStore/validation/compliance-2026-09-22.md)。

应用 Bundle ID 固定为 `com.alkinum.heartpro`。中英上架文案、图标、当前 iPhone/iPad 截图、隐私问卷及待完成审核项见 [App Store 材料](AppStore/README.md)，中英产品网站见 [website](website/README.md)。保留全部分析功能；独立真实 Apple Watch 准确度验证完成前不提交审核。当前网站未部署，主体等资料按用户决定暂时跳过，隐私条款保留草稿；历史截图仅供构图参考。
