// Minimal ESLint flat config to satisfy ESLint v9 CLI when running pre-commit hooks
// Keeps rules empty — projects keep their own rules/plugins via package.json and local configs
module.exports = {
  root: true,
  ignores: [
    'node_modules/**',
    'dist/**',
    'LightRAG/**',
    'dashboard/frontend/node_modules/**'
  ],
  overrides: [
    {
      files: ['**/*.{js,jsx,ts,tsx}'],
      languageOptions: {
        parser: require.resolve('@typescript-eslint/parser')
      },
      plugins: {
        '@typescript-eslint': require('@typescript-eslint/eslint-plugin')
      },
      rules: {
        // Intentionally empty — keep lint rules in package-specific configs
      }
    }
  ]
};
