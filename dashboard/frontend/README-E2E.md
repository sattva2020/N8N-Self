Playwright smoke test

Run locally (after building and serving the app):

```powershell
cd dashboard/frontend
npm ci
npm run build
# run a local static server (e.g. npx serve -s dist -l 5173) or run `npm run preview`
npx serve -s dist -l 5173
# in another shell
npm run e2e
```

Adjust the URL in `tests/e2e/smoke.spec.ts` if the app is served on a different port.
