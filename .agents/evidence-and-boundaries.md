# HeartPro 资料与能力边界

资料核对日期：2026-09-17。以下是规划依据，不是 HeartPro 的临床验证报告。Apple 文档会随 SDK 和系统变化；开发阶段以所用 Xcode SDK 的编译结果、公开 API 文档和真机行为共同确认。

## 1. 已核对的平台事实

| 事实 | 对实现的影响 | 依据 |
| --- | --- | --- |
| `HKElectrocardiogram` 提供 Apple Watch ECG 的只读访问 | 不申请 ECG 写权限，不尝试创建或更新 Watch ECG | A1 |
| 元信息与电压序列分开查询 | 先索引样本，再通过 `HKElectrocardiogramQuery` 获取整条采样 | A1、A2 |
| 电压查询逐条回调并以完成或错误事件结束 | 流式收集、支持取消；完成前不把部分数据标记为完整记录 | A2 |
| ECG 样本带有采样频率、平均心率、分类、症状状态等字段 | 保留原始来源，不把 Apple 分类伪装成 HeartPro 的结果 | A1 |
| 可用 `predicateForObjectsAssociated(electrocardiogram:)` 查询已关联的症状 | 在获准读取相应症状类型后展示 Apple 原有症状；只读关联不代表可新增关联 | A3 |
| `authorizationStatus(for:)` 表示写入授权状态，不能得知读取是否获准 | 空查询应写「暂无可读取记录」，不能断言用户拒绝授权或从未测量 | A4 |
| Anchored query 返回新增样本、删除对象和新 anchor | 使用持久化增量同步、删除传播和可恢复队列 | A5 |
| 后台交付受 entitlement、类型支持和系统调度限制；模拟器不支持相应后台测试 | 前台刷新是可靠路径；后台 ECG 交付的具体可用性列为 P0 真机核对，不承诺实时 | A6、A7 |
| HealthKit HRV 指标为 SDNN，单位是时间 | 与 ECG 自算 RMSSD、SDNN 分开保存来源、时长和算法 | A8 |
| HealthKit 有胸闷／胸痛、心悸、漏跳感、气短、头晕、晕厥等症状类型 | 只映射公开且支持写入的类型；严重程度按对应枚举填写 | A9、A10 |
| 同步标识必须配套同步版本；较高版本可替换相同同步标识的对象 | 症状写回采用可恢复、幂等、带版本的 outbox；真机验证作用域和替换行为 | A11 |

特别注意：A6 的类型说明没有为 ECG 给出明确的独立保证。实现可以验证公开 API 是否接受 ECG 类型，但不能把「HealthKit 支持部分后台更新」写成「所有 Watch ECG 会立即在后台分析」。即使注册成功，也没有准时完成的保证。

## 2. 医学解释边界与用户需求的落地

### 2.1 单导联与「专业分析」

Apple Watch ECG 类似 I 导联，常规记录约 30 秒；实际分析必须读取每条记录的真实时长与采样率，不写死为 30 秒或 512 Hz。Apple 明确表示 ECG App 不能检测心脏病发作。单导联不具备十二导联的空间信息，也不代表连续全天监测。[A12]

HeartPro 的专业性体现在测量可追溯、全段覆盖、误差与置信度透明、图表能定位原始证据，以及对不可测项目拒绝作答。增加小数位、复杂模型或免责声明都不会增加导联的信息量。

| 需求 | 可以交付 | 不可以承诺 |
| --- | --- | --- |
| 心率与节律 | 有效搏动的 bpm、RR、规则性特征、Apple 原始分类 | 短记录证明全天正常；自行确认所有心律失常 |
| 各波段及间隔 | 有足够质量时的 P／QRS／T 边界、PR／QRS／QT、明确的统计样本数 | 每条记录一定能看到 P 波；单导联精确测得所有间隔 |
| 早搏与异常搏动 | 提前出现、形态偏离、长短 RR 组合等候选事件，附时间和复核入口 | 完整识别所有房早、室早、交界性早搏；估计全天早搏负荷 |
| 房颤等节律问题 | 分开展示 Apple 分类；经验证后展示非特异的 RR 不规则提示 | 把 RR 不规则直接叫房颤；把未见 P 波直接叫房颤 |
| 心梗、心肌缺血 | 说明单导联限制；研究性 ST／T 形态测量；症状与专业就诊建议 | 心梗／缺血概率、筛查阴性、排除疾病、闭塞血管定位 |
| 心脏健康分 | 可解释的心电记录参考分、覆盖率、分项理由 | 疾病风险概率、心肌功能、冠脉健康、医疗分诊 |
| HRV | 合格正常搏动片段内的超短时 RMSSD／SDNN及其趋势 | 与五分钟或二十四小时 HRV 正常值互换；推断自主神经疾病 |
| 统计离群点 | RR、幅度、间隔及形态偏差候选，显示原因与噪声排除结果 | 离群点一定是病变；统计常见意味着医学正常 |

### 2.2 参考区间不是诊断阈值

- 可以展示「成人静息条件下常见参考」，但每项须有自己的来源和适用条件。当前核对的 MSD 页面给出 PR 100–200 ms、QRS 70–100 ms；它还区分较长 QRS 与 ≥120 ms 的传导判读界限。因此不能把「QRS <120 ms」统一标为正常，也不能混用不同教材的 PR 下限。[C2]
- 心率的初始成人静息参考拟定为 60–100 bpm，发布前在 ReferenceCatalog 中单独核定出处。运动、训练状态、年龄、药物、既往疾病、导联和测量方式都会影响解释；落在范围外不自动代表疾病。
- P 波时限、幅度及 ST／T 形态依赖导联与边界质量；无法建立适用范围时写「无适用于本测量的统一参考范围」，不能为了填满表格而编造。
- QT 随心率变化，QTc 还取决于校正公式、人群与误差。首版没有足够验证时不标红 QTc，也不把它纳入分数。不得借用单一 440 ms 阈值对所有用户分类。
- HRV 的记录时长、姿势、呼吸、时间段和个体差异会明显影响结果；不同时间尺度的参考值不可直接互换。[C1]
- 范围必须配置化、版本化；未获得适用的公开依据与专家复核的项目不进入面向用户的异常判定。

### 2.3 文案规则

| 场景 | 建议文案 |
| --- | --- |
| 所有分析页面 | 「仅供参考，不能用于医疗用途，不能替代医生诊断。」 |
| 分数旁 | 「仅概括本次可测的心电特征，不代表整体心脏健康。高分不能排除疾病。」 |
| 当天概览 | 「基于今天已记录的 X 条 ECG，其中 Y 条可评估；不代表全天持续监测。」 |
| 没有候选事件 | 「本次可分析片段未发现该类特征；不能据此排除心脏问题。」 |
| 质量不足 | 「信号干扰较多，无法可靠评估此项。」 |
| 间隔不可测 | 「未能可靠定位 P 波／T 波边界，暂不提供 PR／QT 结果。」 |
| 节律候选 | 「检测到 X 处节律或波形变化，建议结合原始波形与症状复核。」 |
| 心梗与缺血模块 | 「单导联 ECG 不能可靠识别或排除心梗、心肌缺血。本结果不能用于判断是否需要急救。」 |
| 严重症状 | 「如出现持续胸痛、明显气短、晕厥等症状，请立即寻求急救帮助，不要等待本应用分析。」 |

严重症状提示根据用户主动报告的症状呈现，与分数和算法是否提示异常无关。提供本地化紧急帮助说明，不擅自拨号或自动向外部联系人发送健康数据。

## 3. 写回健康的边界

1. Apple ECG 及其来源分类、已有症状关系保持只读。公开 API 的关联读取能力不能推导出可将任意新样本挂回 ECG 的能力。
2. HeartPro 自由文本、快速标签、症状发生时间、诱因和附件关系保存在本地；首版不把自由文本塞进 HealthKit 自定义 metadata 来冒充标准备注。
3. 用户可以在备忘编辑页选择「同时记录到健康」，预览具体症状、严重程度和时间后保存。写入的是 **HeartPro 创建的独立症状记录**，在 HeartPro 内关联到 ECG；不保证健康 App 的 ECG 详情页显示该关联。
4. 「紧张」「咖啡」「睡眠不足」「运动后」等上下文标签只保存在本地。算法发现的早搏候选不是用户主观症状，不自动写入为「心悸」或「漏跳感」。
5. 分数、推测疾病、未验证间隔和超短时自算 HRV 首版不写入健康。避免制造重复的 bpm／HRV 数据，污染系统趋势。
6. HealthKit 写入可失败；本地备忘保存成功与健康写入成功分别显示。只允许修改或删除 HeartPro 自己写入的样本。

## 4. 资料清单

以下 A1–A13、C1–C2、D1–D2 已读取对应官网正文或官方文档 JSON；数值参考对 Watch 单导联测量的适用性仍须医学顾问核定。资料存在不代表支持 HeartPro 的准确度主张。

| 编号 | 资料 | 用途 |
| --- | --- | --- |
| A1 | [Apple — HKElectrocardiogram](https://developer.apple.com/documentation/healthkit/hkelectrocardiogram) | ECG 只读、元信息与电压分离 |
| A2 | [Apple — HKElectrocardiogramQuery](https://developer.apple.com/documentation/healthkit/hkelectrocardiogramquery) | 原始电压查询与完成语义 |
| A3 | [Apple — predicateForObjectsAssociated(electrocardiogram:)](https://developer.apple.com/documentation/healthkit/hkquery/predicateforobjectsassociated(electrocardiogram:)) | 已关联症状读取 |
| A4 | [Apple — authorizationStatus(for:)](https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationstatus(for:)) | 不可观测读取权限 |
| A5 | [Apple — HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery) | 增量数据与删除 |
| A6 | [Apple — enableBackgroundDelivery](https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:withcompletion:)) | 后台调度和 entitlement |
| A7 | [Apple — HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery) | 观察更新及真机限制 |
| A8 | [Apple — heartRateVariabilitySDNN](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn) | 系统 HRV 定义 |
| A9 | [Apple — Symptom Type Identifiers](https://developer.apple.com/documentation/healthkit/symptom-type-identifiers) | 症状映射 |
| A10 | [Apple — rapidPoundingOrFlutteringHeartbeat](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/rapidpoundingorflutteringheartbeat) | 示例症状的 severity 类型 |
| A11 | [Apple — HKMetadataKeySyncIdentifier](https://developer.apple.com/documentation/healthkit/hkmetadatakeysyncidentifier) | 幂等写入与版本 |
| A12 | [Apple Support — Take an ECG with the ECG app on Apple Watch](https://support.apple.com/en-us/120278) | 单导联、典型时长、年龄及疾病限制 |
| A13 | [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | 1.4.1 准确度依据；5.1.3 健康数据与 iCloud 限制 |
| C1 | [Shaffer & Ginsberg — An Overview of Heart Rate Variability Metrics and Norms](https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/) | 短时／超短时 HRV 与不可互换的常模 |
| C2 | [MSD Manual Professional — Electrocardiography](https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography) | 已核对间隔定义与该来源的 PR／QRS 数值；发布前核定适用性与目录版本 |
| D1 | [PhysioNet — Lobachevsky University Electrocardiography Database 1.0.1](https://physionet.org/content/ludb/1.0.1/) | 200 条十秒十二导联，有 P／QRS／T 边界标注；选 I 导联做方法验证 |
| D2 | [PhysioNet — QT Database 1.0.0](https://physionet.org/content/qtdb/1.0.0/) | 双导联波段边界测试，注意只对已标注心搏计算误差 |
| D3 | [PhysioNet — MIT-BIH Arrhythmia Database](https://physionet.org/content/mitdb/1.0.0/) | 候选节律基准；本次官方页面返回 502，未核验正文与许可，P0 补核 |

## 5. 必须关闭的证据缺口

- P0：实际 Xcode／Swift 版本、iOS 18 最低支持版本、HealthKit entitlement、症状逐项写入支持、ECG 后台交付、真实样本导联与采样率。
- P0：参考区间逐项出处、所覆盖人群、QTc 适用条件；以版本化 ReferenceCatalog 记录核定结果。
- P3–P5：患者级独立测试集、Watch 同域数据、专家标注、拒答比例及各分组表现；公开医疗设备数据不能替代 Watch 数据验证。
- P4：评分与真实可解释特征的稳定性、重测波动、误导风险；没有疾病标签验证就没有疾病预测能力。
- P5：P 波／T 波端点、房早／室早候选能否在单导联上达到预设目标；未达标保持关闭。
- 发布前：App Store 方法说明、数据保留／删除方案和适用市场的用途审查。仅写「非医疗用途」不会自动改变具有诊断功能的产品性质。[A13]
