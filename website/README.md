# HeartPro website

中英双语 svedocs 0.2.1 产品网站，参照 `../ezarchive/website` 的框架接入，以及 `../sift/apps/site` 的悬浮导航与留白。HeartPro 定制主题使用珊瑚红、暖白/炭灰配色和圆角阅读界面。正式域名配置为 `https://heartpro.alkinum.com`，2026-10-10 已通过 Cloudflare 静态 Worker 自定义域名部署并验证 HTTPS。运营者为 Alkinum，政策和条款已公开；支持邮箱投递仍待验证。

## 本地开发

使用 Node.js 和 pnpm 12.3.4，在此目录执行：

```sh
rtk proxy pnpm install --frozen-lockfile
rtk proxy pnpm dev --host 127.0.0.1 --port 48620
```

生产预览：

```sh
rtk proxy pnpm build
rtk proxy pnpm preview --host 127.0.0.1 --port 48622
```

不要同时运行 dev 和 build：两者会共享 `.svelte-kit` 输出，构建后应重启 dev。生产预览须先 build。

## 结构

- `svedocs.config.ts`：域名、静态构建、主题、双语导航、当前语言本地搜索。
- `src/lib/SupportForm.svelte`、`support-copy.ts`：中英支持表单，仅支持页加载 Turnstile。
- `src/lib/server/support-intake.ts`、`worker.ts`：服务器端 OnFire 接入，客户令牌不返回浏览器。
- `content/pages/{en,zh}`：首页、支持、隐私政策、使用条款、发行状态。
- `content/docs/{en,zh}`：开始使用、数据管理、方法与限制。
- `src/lib/Landing.svelte`：共用首页，真实开发界面截图切换。
- `src/lib/Site.svelte`：根路由和中文首页共用 DocsApp landing slot，保留 SEO/语言/搜索/Markdown twins。
- `src/lib/SiteHeader.svelte`：悬浮毛玻璃标题栏，滚动阴影及移动菜单遮罩；组合框架 Navbar，保留搜索、语言切换、主题和键盘行为。
- `src/lib/messages.ts`：中英界面文案及中文版框架消息。
- `src/lib/site.css`：完整主题 tokens、悬浮导航、首页卡片、文档/政策阅读布局及页脚；文档与导航共用 1160px 容器，左侧菜单 168px（窄桌面 156px），平板/手机折叠导航；包含深浅色、锚点偏移、键盘焦点与减少动画。
- `static/screenshots`：当前 0.6.0 真实模拟器界面的 WebP 副本，保留合成示例标识。`provenance.json` 记录原始截图和网页图片的 SHA-256；上架时使用 `AppStore/screenshots` 中未缩放的 PNG。
- `wrangler.jsonc`：静态页面与 `/api/support` 服务器入口；包含公开产品/类型 ID、IP 频率限制，不包含密钥。

英语首页 `/`，中文 `/zh/`；使用指南 `/docs/` 与 `/docs/zh/`；中文政策/支持 `/zh/privacy/`、`/zh/support/`。本地搜索、语言切换、主题切换、404、sitemap、robots、llms 和 Markdown twins 保留框架实现。

## 检查

```sh
rtk proxy pnpm check
rtk proxy pnpm check:docs
rtk proxy pnpm build
rtk proxy pnpm test
rtk proxy pnpm check:deploy
```

Playwright 启动隔离的构建预览端口 48621，验证 16 个页面、语言/SEO、正式政策运营者与可索引状态、截图加载/切换、深色/手机布局、搜索、章节锚点、404 和机器可读输出。浏览器截图存于 `.svedocs/qa`。Cloudflare dry-run 不会发布。

## 部署

```sh
rtk proxy pnpm build
rtk proxy pnpm test
rtk proxy pnpm run deploy
```

`pnpm run deploy` 使用 `wrangler.jsonc` 中的 `heartpro.alkinum.com` 自定义域名；必须写 `run`，避免调用 pnpm 内置的 deploy 命令。`/tos`、`/tos/` 以及中文路径由 `_redirects` 跳转对应 `/terms/`。线上验证记录见 `../AppStore/evidence/health-fitness-2026-10-09/public-pages.json`。

## App 上架前

1. 确认正式运营主体、联系地址、上线地区、适用法律；确认网站/CDN 和邮箱服务商、日志与支持邮件保留期限、数据处理地区及必要跨境保障。
2. 验证支持工单回复能够送达用户填写的邮箱。本次未发送邮件。
3. 中英政策与条款已生效、公开并使用 Alkinum；实际服务或地区要求改变时同步更新。
4. 界面更新后重新拍摄，并在项目根目录运行 `rtk proxy python3 Tools/prepare_website_screenshots.py`（依赖 Pillow）更新网页图片，同步版本标签。保留合成标识。
5. 支持与政策 HTTPS 已验证，可填入 App Store Connect；后续部署后复查公开页面与邮箱。
6. 独立 Watch 准确度验证完成前，发行页不得改为可下载。获得真实 App Store URL 后再增加下载链接。

网站无需访问或上传用户健康数据。系统分享、Apple 自身 Health 同步、主动发来的支持邮件与网站请求日志须分别解释，不能以 App 本地处理为由笼统宣称网站也不处理任何数据。

## 支持表单与密钥

HeartPro 使用 OnFire 中 Alkinum 租户的专属产品，网站提交到同域 `/api/support`，再由 Worker 签发客户短期令牌、读取当前表单版本并提交工单。原文和偏好回复语言保持不变，不启用 AI 翻译，也不开放历史工单读取。没有健康数据、文件或诊断日志上传。

共享 Turnstile 的公开站点 key 可进入客户端；对应校验 secret 只由 OnFire 持有，网站不能重复消费同一个验证 token。生产域名为 `heartpro.alkinum.com`；服务器校验 origin、输入长度、产品和类型映射，并限制每 IP 每分钟五次尝试。不确定的写入不会自动重试。

`ONFIRE_API_KEY` 只设置为 `heartpro-website` 的 Cloudflare Worker Secret。`.env.example` 仅记录空占位；本地凭据用被忽略的 `.dev.vars`，权限 `600`。通过 stdin 或 `wrangler deploy --secrets-file .dev.vars` 配置，不能将值写进命令行、`PUBLIC_*`、Git 文件、静态资源或截图。不要使用 OnFire 账户级管理 key。

执行 `pnpm test:support` 验证服务器边界，`pnpm test` 验证双语提交、失败恢复和移动布局。测试使用模拟服务，不产生生产工单。生产联调工单或通知邮件需明确测试授权；未验证邮箱投递前不承诺自动回执和邮件回复。

### 2026-10-11 生产联调

四类请求（problem / feature / question / privacy）的 v1 表单均已启用，路由继承 Alkinum 的默认团队。专属产品凭据到期时间为 2027-01-09 14:22（UTC+8），届时须续期或轮换 Worker Secret；一次性值未进入仓库。

生产站点已通过真实 Turnstile 验证，唯一合成测试工单 `79f7222f-813e-47f3-a234-5772d6608893` 已进入 OnFire 的使用咨询队列。中文原文、回复语言 `zh`、应用版本和标注为合成测试的设备信息均已核对。工单为待处理、未分配状态；未发送客服回复，邮件投递仍待验证。

验证通过：类型检查、严格文档检查、静态构建、8 项服务器测试、9 项浏览器测试、部署预检，以及正式网站桌面深浅色和 390px 中文手机页面。Worker 使用 `redirect: manual` 并拒绝重定向，兼容 Cloudflare 原生 fetch；不会把产品凭据转发到重定向地址。失败日志仅含阶段、状态和错误类别，不含正文、邮箱、密钥或原始上游响应。
