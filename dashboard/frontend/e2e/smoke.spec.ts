import { test, expect } from '@playwright/test';

test('smoke: open app root', async ({ page }) => {
  await page.goto('http://localhost:5175/');
  await expect(page).toHaveTitle(/Dashboard|App|index/i);
});
