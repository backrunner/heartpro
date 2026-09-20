import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests', timeout: 45000, workers: 1,
  use: { baseURL: 'http://127.0.0.1:48621', headless: true, viewport: { width: 1365, height: 1000 }, screenshot: 'only-on-failure' },
  webServer: { command: 'rtk proxy pnpm preview --host 127.0.0.1 --port 48621', url: 'http://127.0.0.1:48621', timeout: 60000, reuseExistingServer: false }
});
