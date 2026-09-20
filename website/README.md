# HeartPro website

中英双语 svedocs 0.2.1 产品网站，参照 `../ezarchive/website` 的框架接入，以及 `../sift/apps/site` 的悬浮导航与留白。HeartPro 定制主题使用珊瑚红、暖白/炭灰配色和圆角阅读界面。正式域名配置为 `https://heartpro.alkinum.com`，本次没有部署或修改 DNS。

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
- `content/pages/{en,zh}`：首页、支持、隐私政策、使用条款、发行状态。
- `content/docs/{en,zh}`：开始使用、数据管理、方法与限制。
- `src/lib/Landing.svelte`：共用首页，真实开发界面截图切换。
- `src/lib/Site.svelte`：根路由和中文首页共用 DocsApp landing slot，保留 SEO/语言/搜索/Markdown twins。
- `src/lib/SiteHeader.svelte`：悬浮毛玻璃标题栏，滚动阴影及移动菜单遮罩；组合框架 Navbar，保留搜索、语言切换、主题和键盘行为。
- `src/lib/messages.ts`：中英界面文案及中文版框架消息。
- `src/lib/site.css`：完整主题 tokens、悬浮导航、首页卡片、文档/政策阅读布局及页脚；文档与导航共用 1160px 容器，左侧菜单 168px（窄桌面 156px），平板/手机折叠导航；包含深浅色、锚点偏移、键盘焦点与减少动画。
- `static/screenshots`：当前 0.6.0 真实模拟器界面的 WebP 副本，保留合成示例标识。`provenance.json` 记录原始截图和网页图片的 SHA-256；上架时使用 `AppStore/screenshots` 中未缩放的 PNG。
- `wrangler.jsonc`：仅静态资产托管，无服务器、secret、客服表单、分析脚本或支付集成。

英语首页 `/`，中文 `/zh/`；使用指南 `/docs/` 与 `/docs/zh/`；中文政策/支持 `/zh/privacy/`、`/zh/support/`。本地搜索、语言切换、主题切换、404、sitemap、robots、llms 和 Markdown twins 保留框架实现。

## 检查

```sh
rtk proxy pnpm check
rtk proxy pnpm check:docs
rtk proxy pnpm build
rtk proxy pnpm test
rtk proxy pnpm check:deploy
```

Playwright 启动隔离的构建预览端口 48621，验证 16 个页面、语言/SEO、草稿 noindex、截图加载/切换、深色/手机布局、搜索、章节锚点、404 和机器可读输出。浏览器截图存于 `.svedocs/qa`。Cloudflare dry-run 不会发布。

## 发布前

1. 确认正式运营主体、联系地址、上线地区、适用法律；确认网站/CDN 和邮箱服务商、日志与支持邮件保留期限、数据处理地区及必要跨境保障。
2. 确认 `support@heartpro.alkinum.com` 实际可收信。本次未发送邮件。
3. 定稿中英隐私与条款，填写生效日期，移除草稿和 `robots: "noindex, follow"`。
4. 界面更新后重新拍摄，并在项目根目录运行 `rtk proxy python3 Tools/prepare_website_screenshots.py`（依赖 Pillow）更新网页图片，同步版本标签。保留合成标识。
5. 配置实际域名/DNS，部署后验证 HTTPS 支持与政策公开可访问，再填入 App Store Connect。
6. 独立 Watch 准确度验证完成前，发行页不得改为可下载。获得真实 App Store URL 后再增加下载链接。

网站无需访问或上传用户健康数据。系统分享、Apple 自身 Health 同步、主动发来的支持邮件与网站请求日志须分别解释，不能以 App 本地处理为由笼统宣称网站也不处理任何数据。
