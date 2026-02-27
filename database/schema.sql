-- M8x Table — D1 Database Schema (reference copy)
--
-- This file shows the FINAL state after all migrations.
-- Actual schema changes go in database/migrations/.
--
-- Migrations applied:
--   0001_initial.sql
--   0002_translation_redesign.sql
--   0003_vocab_and_source_locale.sql

-- ============================================================
-- Users (auth handled by Clerk)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id               TEXT PRIMARY KEY,            -- Clerk user ID
  display_name     TEXT NOT NULL DEFAULT '',
  profile_picture  TEXT,                        -- R2 key
  locale           TEXT NOT NULL DEFAULT 'en',  -- preferred app locale
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Recipes
--
-- Original text fields (title, description, tips) are stored in
-- source_locale. Translations to other locales live in
-- recipe_translations.
-- ============================================================
CREATE TABLE IF NOT EXISTS recipes (
  id               TEXT PRIMARY KEY,
  owner_user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_locale    TEXT NOT NULL DEFAULT 'en',  -- language the recipe was authored in
  title            TEXT NOT NULL DEFAULT '',     -- in source_locale
  description      TEXT NOT NULL DEFAULT '',     -- in source_locale
  tips             TEXT NOT NULL DEFAULT '',     -- in source_locale
  cover_image      TEXT,                        -- R2 key
  category         TEXT NOT NULL DEFAULT '',
  difficulty       TEXT NOT NULL DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  prep_time        INTEGER,                     -- minutes
  cook_time        INTEGER,                     -- minutes
  servings_min     INTEGER,
  servings_max     INTEGER,
  calories         INTEGER,
  carbs            REAL,
  protein          REAL,
  fat              REAL,
  wine_pairing     TEXT,
  tags             TEXT NOT NULL DEFAULT '[]',   -- JSON array
  is_favorite      INTEGER NOT NULL DEFAULT 0,
  is_deleted       INTEGER NOT NULL DEFAULT 0,
  deleted_at       TEXT,
  forked_from_url  TEXT,                        -- set when imported from a URL
  video            TEXT,                        -- R2 key
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  last_modified_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_recipes_owner    ON recipes(owner_user_id);
CREATE INDEX idx_recipes_deleted  ON recipes(is_deleted);
CREATE INDEX idx_recipes_favorite ON recipes(is_favorite);
CREATE INDEX idx_recipes_category ON recipes(category);

-- ============================================================
-- Recipe Translations (optional — only for non-source locales)
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_translations (
  id          TEXT PRIMARY KEY,
  recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  locale      TEXT NOT NULL,
  title       TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  tips        TEXT NOT NULL DEFAULT '',
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(recipe_id, locale)
);

-- ============================================================
-- Ingredient Vocabulary (user-scoped lookup for autocomplete)
--
-- Each entry represents a unique ingredient concept in a user's
-- personal dictionary. Names per locale live in the translations
-- table. Shared across all the user's recipes.
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

CREATE INDEX idx_ivt_vocab ON ingredient_vocab_translations(vocab_id);
CREATE INDEX idx_ivt_name  ON ingredient_vocab_translations(name);

-- ============================================================
-- Recipe Ingredients (per-recipe usage, references vocab)
--
-- amount + unit live here (per-recipe). Unit is a standardized
-- code (g, ml, cup, tbsp, tsp, oz, lb, kg, L, piece, …);
-- the app handles display translation of unit labels.
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id                  TEXT PRIMARY KEY,
  recipe_id           TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient_vocab_id TEXT NOT NULL REFERENCES ingredient_vocab(id),
  amount              REAL,
  unit                TEXT NOT NULL DEFAULT '',
  sort_order          INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_vocab  ON recipe_ingredients(ingredient_vocab_id);

-- ============================================================
-- Tool Vocabulary (user-scoped lookup for autocomplete)
--
-- Same pattern as ingredient_vocab. Each entry is a unique tool
-- concept in the user's dictionary.
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
-- Recipe Tools (M:N join, references vocab)
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_tools (
  id            TEXT PRIMARY KEY,
  recipe_id     TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  tool_vocab_id TEXT NOT NULL REFERENCES tool_vocab(id),
  sort_order    INTEGER NOT NULL DEFAULT 0,
  UNIQUE(recipe_id, tool_vocab_id)
);

CREATE INDEX idx_recipe_tools_recipe ON recipe_tools(recipe_id);

-- ============================================================
-- Steps
--
-- description is in the parent recipe's source_locale.
-- Translations to other locales live in step_translations.
-- ============================================================
CREATE TABLE IF NOT EXISTS steps (
  id           TEXT PRIMARY KEY,
  recipe_id    TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  description  TEXT NOT NULL,                   -- in recipe's source_locale
  step_type    TEXT NOT NULL DEFAULT 'active_cook' CHECK (step_type IN ('prep', 'active_cook')),
  time_minutes INTEGER,
  image        TEXT,                            -- R2 key
  video        TEXT,                            -- R2 key
  sort_order   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_steps_recipe ON steps(recipe_id);

-- ============================================================
-- Step Translations (optional — only for non-source locales)
-- ============================================================
CREATE TABLE IF NOT EXISTS step_translations (
  id          TEXT PRIMARY KEY,
  step_id     TEXT NOT NULL REFERENCES steps(id) ON DELETE CASCADE,
  locale      TEXT NOT NULL,
  description TEXT NOT NULL,
  UNIQUE(step_id, locale)
);

CREATE INDEX idx_step_translations_step ON step_translations(step_id);

-- ============================================================
-- Custom Categories (per user)
-- ============================================================
CREATE TABLE IF NOT EXISTS custom_categories (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, name)
);

CREATE INDEX idx_custom_categories_user ON custom_categories(user_id);

-- ============================================================
-- Collections
-- ============================================================
CREATE TABLE IF NOT EXISTS collections (
  id            TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  visibility    TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'shared', 'public')),
  is_pinned     INTEGER NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_collections_owner ON collections(owner_user_id);

-- ============================================================
-- Collection-Recipe join table
-- ============================================================
CREATE TABLE IF NOT EXISTS collection_recipes (
  id            TEXT PRIMARY KEY,
  collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  recipe_id     TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  UNIQUE(collection_id, recipe_id)
);

-- ============================================================
-- Shopping List
-- ============================================================
CREATE TABLE IF NOT EXISTS shopping_list (
  id        TEXT PRIMARY KEY,
  user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  added_at  TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, recipe_id)
);

-- ============================================================
-- Meal Plan
-- ============================================================
CREATE TABLE IF NOT EXISTS meal_plan (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date       TEXT NOT NULL,                     -- YYYY-MM-DD
  meal_type  TEXT NOT NULL DEFAULT 'other' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
  recipe_id  TEXT REFERENCES recipes(id) ON DELETE SET NULL,
  note       TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_meal_plan_user_date ON meal_plan(user_id, date);
