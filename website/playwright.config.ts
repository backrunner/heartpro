import { defineConfig } from '@playwright/test';
const previewPort = Number(process.env.HEARTPRO_PREVIEW_PORT ?? 48621);
if (!Number.isInteger(previewPort) || previewPort < 1 || previewPort > 65535) throw new Error('Invalid HEARTPRO_PREVIEW_PORT');
const previewURL = `http://127.0.0.1:${previewPort}`;
export default defineConfig({
  testDir: './tests', testMatch: '**/*.spec.ts', timeout: 45000, workers: 1,
  use: { baseURL: previewURL, headless: true, viewport: { width: 1365, height: 1000 }, screenshot: 'only-on-failure' },
  webServer: { command: `rtk proxy pnpm preview --host 127.0.0.1 --port ${previewPort}`, url: previewURL, timeout: 60000, reuseExistingServer: false }
});
