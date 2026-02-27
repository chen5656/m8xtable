# Schema Design Decisions

## Resolved

### Multilingual strategy (migration 0003)
- **Source locale on recipes**: `recipes.source_locale` tracks the original language.
  Title, description, tips live directly on `recipes` in that language.
  `recipe_translations` is optional — only for translations to other locales.
- **All languages supported**: `source_locale` is free-form text, not restricted
  to a fixed set. App UI locales (`en`, `zh-Hans`) are separate from recipe
  content locales.
- **Ingredient vocabulary**: User-scoped `ingredient_vocab` + `ingredient_vocab_translations`.
  Each ingredient concept is defined once and referenced by `recipe_ingredients`.
  Enables autocomplete, translate-once, and shopping-list aggregation by `vocab_id`.
- **Tool vocabulary**: User-scoped `tool_vocab` + `tool_vocab_translations`.
  Same pattern as ingredients. Enables autocomplete, per-tool translation,
  and filtering recipes by tool.
- **Units**: Standardized code on `recipe_ingredients.unit` (g, ml, cup, tbsp, …).
  App handles display translation of unit labels. Not stored in translation tables.
- **Steps**: `description` on `steps` in the recipe's source locale.
  `step_translations` for other locales.

### Removed / deferred
- `ingredient_vocab` (old autocomplete-only table from 0001) — replaced by the
  new vocab lookup design.
- `collection_shares` — sharing deferred to future.

## Open

- **Custom categories**: `custom_categories.name` is free text. Should this also
  be a vocab-style translatable entity? (low priority)
- **Wine pairing**: Currently free text on `recipes`. May want translation support
  later.

## Important

Don't implement any feature yet.
