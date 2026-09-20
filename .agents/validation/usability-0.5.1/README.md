# 0.5.1 界面、引导与短时 HRV 验证

2026-09-19。详细设计和 HRV 规则见 [设计文档](../../heart-health-0.5.md)。

- 44 项 Swift 核心测试通过，见 [日志](core-tests.log)。新增/调整用例覆盖：30秒记录中间有间隔被排除时保留两侧、SDNN/RMSSD数值、45 bpm慢心率30秒记录、不依赖节律评分数量门槛、拒绝跨ID或时间缺口配对、非有限值/过碎间隔不输出结果。临床准确性仍未验证。
- `python3 Tools/localization.py --check`：643 个键，六种语言和占位符检查通过。翻译未经过专业母语医学审校。
- iPhone Debug签名构建与 `codesign --verify --deep --strict` 通过，见 [真机构建](device-build.log)。保留原有 iPad 方向配置警告；AppIntents 未接入的元数据提示不阻止构建。
- iOS Simulator arm64 `build-for-testing` 通过，应用、存储/PDF测试和UI测试均可编译，见 [模拟器构建](simulator-build.log)。
- 已安装并启动到 [REDACTED PERSONAL NAME] 的 iPhone；设备查询确认 `app.heartpro.ios` 版本 `0.5.1`，构建号 `1`。见 [安装](device-install.log) 与 [启动](device-launch.log)。未通过工具读取用户健康数据，也未将成功启动视为界面全流程验收。

新增指南 UI 用例覆盖首次展示、前后翻页、完成后重启不再展示、设置重看和大字号德语。原有UI用例显式使用 `--skip-guide`；指南专项使用仅在UITest模式生效的 `--reset-guide`。

本轮尝试运行应用测试、指南测试和每日心脏健康UI测试，153秒后仍未进入测试用例，随后终止本任务测试进程。日志显示 `IDELaunchiPhoneSimulatorLauncher` 和 `waiting for workers to materialize`，尚无断言结果，见 [测试启动日志](native-tests-attempt.log) 和 [进程采样](test-launch-sample.txt)。随后单独向同一模拟器安装新版也在40秒后超时。不能声称这些UI或App测试通过。

待验证：新指南和导航在真实设备上的逐页操作、大字号完整布局、VoiceOver导航，以及真实30秒Watch记录上的HRV筛选适用性。核心合成测试不等于临床验证。
