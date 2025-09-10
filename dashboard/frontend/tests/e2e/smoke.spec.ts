import { test, expect } from '@playwright/test';

test('smoke: open app root', async ({ page }) => {
  // by default CI should run after build and serve the app; adjust URL if needed
  await page.goto('http://localhost:5173/');
  await expect(page).toHaveTitle(/Dashboard|App|index/i);
});
