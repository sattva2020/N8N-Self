const { devices } = require('@playwright/test');

module.exports = {
  testDir: './e2e',
  timeout: 30000,
  use: {
    headless: true,
  },
  webServer: {
    // Use our lightweight static server to serve dist on CI/local
    command: 'npm run serve-dist',
    // If a server is already running locally, reuse it (convenient for dev).
    reuseExistingServer: true,
    // Health check URL Playwright will poll. Use url only (don't set port) — Playwright requires either port or url, not both.
    url: 'http://127.0.0.1:5175/',
    timeout: 120000,
  },
};
