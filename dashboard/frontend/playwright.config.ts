import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  use: {
    headless: true,
  },
  webServer: {
    // Use our lightweight static server to serve dist on CI/local
    command: 'npm run serve-dist',
    // If a server is already running locally, reuse it (convenient for dev).
    reuseExistingServer: true,
    // Prefer polling a port instead of a full url to avoid host/url mismatches.
    port: 5175,
    timeout: 120_000,
  },
})
