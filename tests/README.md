# M8x Table — Test Suite

Tests are written in Jest + TypeScript. They cover every feature area in `Plan.md`.

**Important**: Tests are written ahead of implementation. Feature implementations are `TODO` stubs.

## Structure

| File | Coverage |
|------|---------|
| `tests/database/schema.test.ts` | D1 schema integrity |
| `tests/auth.test.ts` | Sign in with Apple, profile, account deletion |
| `tests/recipes.test.ts` | Recipe CRUD, draft model, all entry methods |
| `tests/recipe-translations.test.ts` | Multi-language support |
| `tests/collections.test.ts` | Collections, visibility, sharing |
| `tests/shopping-list.test.ts` | Shopping list (recipe tab + ingredients tab) |
| `tests/meal-plan.test.ts` | Meal plan calendar |
| `tests/search-filter.test.ts` | Keyword search and filters |
| `tests/r2-media.test.ts` | R2 presigned URL, upload, delete |
| `tests/ai-providers.test.ts` | All AI provider integrations |
| `tests/i18n.test.ts` | Localisation (en, zh-Hans) |
| `tests/error-handling.test.ts` | Error messages, Sentry logging |
| `tests/settings.test.ts` | API key management, account settings |

## Run

```bash
npm test               # all tests
npm test -- --watch    # watch mode
npm test <file>        # single file
```
