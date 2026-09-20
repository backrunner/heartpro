import { test, expect } from '@playwright/test';
import { mkdir } from 'node:fs/promises';

const routes = ['/', '/support/', '/privacy/', '/terms/', '/release/', '/docs/', '/docs/data/', '/docs/methods/', '/zh/', '/zh/support/', '/zh/privacy/', '/zh/terms/', '/zh/release/', '/docs/zh/', '/docs/zh/data/', '/docs/zh/methods/'];
test('all content routes, legal drafts and page metadata', async ({ page }) => {
  for (const path of routes) {
    const response = await page.goto(path);
    expect(response?.status(), path).toBe(200);
    await expect(page.locator('main')).toHaveCount(1);
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /https:\/\/heartpro\.alkinum\.com\//);
    await expect(page.locator('html')).toHaveAttribute('lang', path.includes('zh') ? /zh/ : 'en');
    if (/privacy|terms/.test(path)) await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);
  }
});
for (const language of ['en', 'zh']) {
  test(`${language} homepage, preview controls, themes and mobile layout`, async ({ page }) => {
    await mkdir('.svedocs/qa', { recursive: true });
    await page.goto(language === 'en' ? '/' : '/zh/');
    const image = page.locator('.hp-device img');
    await expect(image).toBeVisible();
    await expect.poll(() => image.evaluate((e: HTMLImageElement) => e.naturalWidth)).toBeGreaterThan(0);
    await page.getByRole('button', { name: language === 'en' ? 'History' : '历史记录', exact: true }).click();
    await expect(image).toHaveAttribute('src', /history/);
    await page.getByRole('button', { name: language === 'en' ? 'Trends' : '变化趋势', exact: true }).click();
    await expect(image).toHaveAttribute('src', /trends/);
    const primary = page.locator('.hp-actions a').first();
    await expect(primary).toHaveAttribute('href', language === 'en' ? '/docs' : '/docs/zh');
    await page.getByRole('button', { name: language === 'en' ? 'ECG' : '心电波形', exact: true }).click();
    await page.screenshot({ path: `.svedocs/qa/${language}-desktop.png`, fullPage: true });
    await page.getByRole('button', { name: /Switch to .* theme|切换到.*主题/ }).click();
    await page.screenshot({ path: `.svedocs/qa/${language}-dark.png`, fullPage: true });
    await page.setViewportSize({ width: 390, height: 844 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.screenshot({ path: `.svedocs/qa/${language}-mobile.png`, fullPage: true });
    const menu = page.getByRole('button', { name: /Open menu|打开菜单/ });
    if (await menu.isVisible()) {
      await menu.click();
      await expect(page.getByRole('link', { name: language === 'en' ? 'Support' : '支持', exact: true }).first()).toBeVisible();
    }
  });
}
test('search, article anchors, unknown routes and machine-readable content', async ({ page, request }) => {
  await page.goto('/docs/zh/');
  await page.getByRole('button', { name: /搜索文档|Search documentation/ }).click();
  const input=page.getByRole('combobox', { name: '搜索关键词' });
  await input.fill('数据');
  await expect(page.getByRole('dialog')).toContainText('数据');
  await page.keyboard.press('Escape');
  await page.goto('/docs/methods/#evidence-status');
  await expect(page.locator('#evidence-status')).toBeInViewport();
  const missing = await page.goto('/page-that-does-not-exist/');
  expect(missing?.status()).toBe(404);
  await expect(page.getByRole('heading', { level: 1 })).toContainText(/not found|找不到/i);
  for (const path of ['/llms.txt', '/llms-full.txt', '/index.md', '/sitemap.xml', '/robots.txt']) {
    const response = await request.get(path); expect(response.status(), path).toBe(200);
  }
});
