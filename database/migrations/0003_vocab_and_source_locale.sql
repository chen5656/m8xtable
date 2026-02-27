-- M8x Table — Migration 0003: Vocabulary Lookup Tables & Source Locale
--
-- Design decisions:
--   1. Recipes keep original text in source_locale; recipe_translations is
--      optional (for non-source locales only).
--   2. Ingredients use a user-scoped vocabulary lookup table.
--      - Enables autocomplete, translate-once-use-everywhere, and reliable
--        shopping-list aggregation (same vocab_id = same ingredient).
--   3. Tools use a user-scoped vocabulary lookup table.
--      - Enables autocomplete, per-tool translation, recipe filtering by tool.
--   4. Unit on recipe_ingredients is a standardized code (g, ml, cup, tbsp…);
--      the app handles display translation — no unit in translation tables.
--   5. All languages supported (source_locale is free-form, not restricted to
--      en / zh-Hans).
--
-- Changes:
--   a. Add source_locale, title, description, tips back to recipes.
--   b. Drop tools column from recipe_translations (tools are now structured).
--   c. Add description back to steps.
--   d. Create ingredient_vocab + ingredient_vocab_translations.
--   e. Create recipe_ingredients (replaces old ingredients table).
--   f. Create tool_vocab + tool_vocab_translations.
--   g. Create recipe_tools (M:N join).
--   h. Drop old ingredients, ingredient_translations tables.

-- ============================================================
-- a. Recipes: add source_locale, restore text fields
-- ============================================================
ALTER TABLE recipes ADD COLUMN source_locale TEXT NOT NULL DEFAULT 'en';
ALTER TABLE recipes ADD COLUMN title TEXT NOT NULL DEFAULT '';
ALTER TABLE recipes ADD COLUMN description TEXT NOT NULL DEFAULT '';
ALTER TABLE recipes ADD COLUMN tips TEXT NOT NULL DEFAULT '';

-- ============================================================
-- b. recipe_translations: drop tools (now a structured table)
-- ============================================================
ALTER TABLE recipe_translations DROP COLUMN tools;

-- ============================================================
-- c. Steps: restore description
-- ============================================================
ALTER TABLE steps ADD COLUMN description TEXT NOT NULL DEFAULT '';

-- ============================================================
-- d. Ingredient vocabulary (user-scoped lookup for autocomplete)
-- ============================================================
CREATE TABLE IF NOT EXISTS ingredient_vocab (
  id            TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_ingredient_vocab_owner ON ingredient_vocab(owner_user_id);

CREATE TABLE IF NOT EXISTS ingredient_vocab_translations (
  id       TEXT PRIMARY KEY,
  vocab_id TEXT NOT NULL REFERENCES ingredient_vocab(id) ON DELETE CASCADE,
  locale   TEXT NOT NULL,
  name     TEXT NOT NULL,
  UNIQUE(vocab_id, locale)
);

CREATE INDEX idx_ivt_vocab  ON ingredient_vocab_translations(vocab_id);
CREATE INDEX idx_ivt_name   ON ingredient_vocab_translations(name);

-- ============================================================
-- e. Recipe ingredients (per-recipe usage, references vocab)
-- ============================================================
DROP TABLE IF EXISTS ingredient_translations;
DROP TABLE IF EXISTS ingredients;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id                  TEXT PRIMARY KEY,
  recipe_id           TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient_vocab_id TEXT NOT NULL REFERENCES ingredient_vocab(id),
  amount              REAL,
  unit                TEXT NOT NULL DEFAULT '',   -- standardized code: g, ml, cup, tbsp, tsp, oz, lb, kg, L, piece, etc.
  sort_order          INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_vocab  ON recipe_ingredients(ingredient_vocab_id);

-- ============================================================
-- f. Tool vocabulary (user-scoped lookup for autocomplete)
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_vocab (
  id            TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_tool_vocab_owner ON tool_vocab(owner_user_id);

CREATE TABLE IF NOT EXISTS tool_vocab_translations (
  id       TEXT PRIMARY KEY,
  vocab_id TEXT NOT NULL REFERENCES tool_vocab(id) ON DELETE CASCADE,
  locale   TEXT NOT NULL,
  name     TEXT NOT NULL,
  UNIQUE(vocab_id, locale)
);

CREATE INDEX idx_tvt_vocab ON tool_vocab_translations(vocab_id);
CREATE INDEX idx_tvt_name  ON tool_vocab_translations(name);

-- ============================================================
-- g. Recipe tools (M:N join, references vocab)
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_tools (
  id            TEXT PRIMARY KEY,
  recipe_id     TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  tool_vocab_id TEXT NOT NULL REFERENCES tool_vocab(id),
  sort_order    INTEGER NOT NULL DEFAULT 0,
  UNIQUE(recipe_id, tool_vocab_id)
);

CREATE INDEX idx_recipe_tools_recipe ON recipe_tools(recipe_id);
