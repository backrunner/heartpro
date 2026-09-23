# 2026-09-20 验证基线

最新修改与验证见 [2026-09-22 合规复核](compliance-2026-09-22.md)。下表是历史记录，不代表新源码全部检查。

核对日：2026-09-20（America/Chicago；本机部分日志显示次日 +0800）。

| 检查 | 结果 | 证据/限制 |
| --- | --- | --- |
| 纯 Swift 核心 | **48 项通过** | `../evidence/core-tests.log`；合成数值与领域逻辑，不是临床验证 |
| 六语资源 | **670 键通过** | `Tools/localization.py --check`；含新隐私/支持/医生提醒；不是母语医学审校 |
| Release iOS | **无签名构建通过** | `DerivedData-AppStore`；`../evidence/release-bundle.json` 确认 `com.alkinum.heartpro`、0.6.0 (1)、iOS 18；无分发 archive、无上传 |
| 原生测试 | **11 项通过，无失败/跳过/运行时警告** | `../evidence/native-tests-summary.json`、`TestResults/AppStore-Native-Final.xcresult`；含临时 PDF 删除、仓库清空、六语 PDF 完整性 |
| 截图 UI 测试 | **中英 iPhone/iPad 流程通过** | `../screenshots/*/manifest.json` 记录实际 xcresult；主流程包含历史、每日、趋势、波形、备忘及设置。非所有 UI 用例的全量回归 |
| 当前上架截图 | **24 张原始 PNG** | 0.6.0 (1)，iPhone 1320×2868、iPad 2064×2752；各设备每语 6 张；逐组视觉复核与哈希见 manifest |
| 隐私 manifest/entitlements | **plist 校验通过** | 无跟踪；文件时间戳/偏好声明；HealthKit entitlement |
| 商店文本/图标 | **本地检查通过** | `Tools/check_appstore.py`；字段长度、包名、清单和 1024 RGB PNG |
| 网站类型 | **0 errors, 0 warnings** | `pnpm check` |
| svedocs 内容 | **16 页，78 搜索条目，0 errors, 0 warnings** | `pnpm check:docs`，含双语、链接、资源 |
| 网站生产构建 | **通过** | `../evidence/website-build.log`；静态输出 |
| 网站浏览器 | **4 项通过** | `../evidence/website-tests.log`；16 路由、SEO、隐私草稿 noindex、图片切换、中英/手机/深色、搜索、章节锚点、404、llms/sitemap/robots/Markdown |
| 网站视觉检查 | **已查看浏览器截图** | `../../website/.svedocs/qa/`；已换成 0.6.0 真实 UI 合成示例，含中英/手机/深色布局；本次未测试真人医学理解 |
| 定制网站主题与文章布局 | **检查与构建通过；4 项浏览器测试通过** | `../evidence/website-theme-*.log`；文章与悬浮导航共用宽度，左栏收窄。`../evidence/website-article-layout.json` 覆盖中英 320–1440px 的 16 个布局，无横向溢出；侧栏/手机菜单跳转、选中态及锚点通过，深浅色截图已查看 |
| Cloudflare 部署预检 | **dry-run 通过** | `../evidence/website-deploy-dry-run.log`；180 静态资产；未部署 |
| 公网 HTTPS/支持邮件 | **未验证可用** | 公网域名 HTTPS 请求未成功；未发送邮件；上线前必须完成 |
| 提交门槛 | **预期失败** | `Tools/check_appstore.py --submission`；准确度、主体、政策、真机、签名/账户仍缺 |

模拟器早期尝试曾在启动、数据迁移和测试进程连接时失败，日志予以保留。随后仅对本任务专用设备进行启动/关闭和重试，取得上述通过结果；没有重置全局模拟器服务或删除用户数据。模拟器上的通过结果不替代 `device-checklist.md` 的真实 HealthKit 验收。

安静模式构建日志可能为空；构建成功来自命令退出码 0 和产物元数据，不把空日志等同失败，也不把产物存在等同签名/上架成功。源文件 SHA-256 清单用于定位本次证据版本。更改算法或 UI 后需更新相关证据，不能沿用无关版本截图。
