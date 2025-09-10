import { defineConfig } from '@playwright/test';

// Ensure we declare a chromium project so CI can target --project=chromium
// and configure Playwright to write artifacts into `playwright-report`.
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  // Where Playwright will store traces/screenshots/videos created during the run
  outputDir: 'playwright-report',
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  use: {
    headless: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
  webServer: {
    // Use our lightweight static server to serve dist on CI/local
    command: 'npm run serve-dist',
    // If a server is already running locally, reuse it (convenient for dev).
    reuseExistingServer: true,
    // Prefer polling a port instead of a full url to avoid host/url mismatches.
    port: 5175,
    timeout: 120_000,
  },
});
