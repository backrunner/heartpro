import { test, expect } from '@playwright/test';
import { mkdir } from 'node:fs/promises';

for (const locale of ['en', 'zh']) test(`support is read-only and never submits data: ${locale}`, async ({ page }) => {
  const external: string[] = [];
  const writes: string[] = [];
  page.on('request', request => {
    if (/challenges\.cloudflare\.com|onfire\.alkinum\.com|\/api\/support/.test(request.url())) external.push(request.url());
    if (!['GET', 'HEAD'].includes(request.method())) writes.push(request.url());
  });
  await page.goto(locale === 'zh' ? '/zh/support/' : '/support/');
  await expect(page.locator('main')).toContainText(locale === 'zh' ? '只读帮助页面' : 'read-only help page');
  await expect(page.locator('main form, main input, main textarea, main select, main iframe')).toHaveCount(0);
  await expect(page.locator('a[href^="mailto:"]')).toHaveCount(0);
  await expect(page.locator('main')).toContainText(locale === 'zh' ? '请勿提交任何个人资料' : 'Do not submit any personal information');
  await expect(page.locator('main a[href*="methods"]')).not.toHaveCount(0);
  await page.getByRole('link', { name: locale === 'zh' ? '隐私政策' : 'privacy policy', exact: true }).first().click();
  await expect(page).toHaveURL(/privacy/);
  await expect(page.locator('main')).toContainText(locale === 'zh' ? '旧支持接口' : 'former support endpoint');
  expect(external).toEqual([]);
  expect(writes).toEqual([]);
});

test('read-only help remains usable on mobile, desktop and without JavaScript', async ({ browser, page }) => {
  await mkdir('.svedocs/qa', { recursive: true });
  for (const locale of ['en', 'zh']) {
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(locale === 'zh' ? '/zh/support/' : '/support/');
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      await expect(page.locator('main form')).toHaveCount(0);
      if (width === 390 || width === 1440) await page.screenshot({ path: `.svedocs/qa/${locale}-help-${width}.png`, fullPage: true });
    }
  }
  const context = await browser.newContext({ javaScriptEnabled: false });
  const offlineUI = await context.newPage();
  await offlineUI.goto('/support/');
  await expect(offlineUI.getByRole('heading', { name: 'No records appear' })).toBeVisible();
  await expect(offlineUI.locator('main form')).toHaveCount(0);
  await context.close();
});
