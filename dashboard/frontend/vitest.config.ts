import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
  setupFiles: './src/setupTests.ts',
  // only include project tests in src and test folders
  include: ['src/**/*.test.{ts,tsx,js,jsx}', 'src/**/*.spec.{ts,tsx,js,jsx}', 'tests/**/*.test.{ts,tsx,js,jsx}'],
  exclude: ['**/node_modules/**', '**/e2e/**', '**/tests/e2e/**']
  }
})
