/// <reference types="vitest" />
/// <reference types="@testing-library/jest-dom" />

// Provide global helpers for tests
declare const test: import('vitest').TestFn
declare const expect: import('vitest').Expect
declare const vi: import('vitest').Vi
declare function describe(name: string, fn: () => void): void
declare function it(name: string, fn: () => void): void
declare function beforeEach(fn: () => void): void
declare function afterEach(fn: () => void): void
