import { defineConfig } from 'svedocs/config';
import { en, zh } from './src/lib/messages.ts';

export default defineConfig({
  site: { name: 'HeartPro', title: 'HeartPro', description: 'Your heart records, in perspective. A private, native companion to Apple Health.', url: 'https://heartpro.alkinum.com' },
  build: { mode: 'static' },
  theme: {
    defaultMode: 'system', readingStyle: 'plain',
    palette: { accent: '#dc4055', neutral: 'slate' },
    fonts: { sans: '"Avenir Next", -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", sans-serif', mono: '"SFMono-Regular", Consolas, monospace' },
    radius: '16px', brand: { label: 'HeartPro', href: '/', logo: '/app-icon.png', mark: false },
    nav: [
      { label: 'Overview', labelKey: 'site.overview', href: '/' },
      { label: 'Guide', labelKey: 'nav.documentation', href: '/docs' },
      { label: 'Support', labelKey: 'site.support', href: '/support' }
    ],
    footer: { text: 'HeartPro · A little closer to your own rhythm.', links: [
      { label: 'Privacy', labelKey: 'site.privacy', href: '/privacy' },
      { label: 'Methods', labelKey: 'site.methods', href: '/docs/methods' },
      { label: 'Terms', labelKey: 'site.terms', href: '/terms' },
      { label: 'Support', labelKey: 'site.support', href: '/support' }
    ] }
  },
  search: { provider: 'local', scope: 'current' }, ai: false,
  agent: { enabled: true, markdown: true, llms: true, negotiation: false },
  checks: { assets: true, translations: true },
  i18n: {
    defaultLocale: 'en', prefixDefaultLocale: false,
    locales: [{ code: 'en', label: 'English', hreflang: 'en', ogLocale: 'en_US' }, { code: 'zh', label: '简体中文', hreflang: 'zh-CN', ogLocale: 'zh_CN' }],
    messages: { en, zh }
  }
});
