-- m8xtable — Initial D1 Schema
-- Single shared database for all users

-- ============================================================
-- Users (app profile; auth is handled by Clerk)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id               TEXT PRIMARY KEY,            -- Clerk user ID
  display_name     TEXT NOT NULL DEFAULT '',
  profile_picture  TEXT,                        -- R2 key
  locale           TEXT NOT NULL DEFAULT 'en',
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Recipes
-- ============================================================
CREATE TABLE IF NOT EXISTS recipes (
  id               TEXT PRIMARY KEY,
  owner_user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title            TEXT NOT NULL DEFAULT '',
  description      TEXT NOT NULL DEFAULT '',
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
  tags             TEXT NOT NULL DEFAULT '[]',  -- JSON array
  tools            TEXT NOT NULL DEFAULT '',    -- tools/equipment
  tips             TEXT NOT NULL DEFAULT '',    -- tips/notes
  is_favorite      INTEGER NOT NULL DEFAULT 0,
  is_deleted       INTEGER NOT NULL DEFAULT 0,
  deleted_at       TEXT,
  forked_from_url  TEXT,                        -- set when imported from a URL (§3.1)
  video            TEXT,                        -- R2 key
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  last_modified_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_recipes_owner    ON recipes(owner_user_id);
CREATE INDEX idx_recipes_deleted  ON recipes(is_deleted);
CREATE INDEX idx_recipes_favorite ON recipes(is_favorite);
CREATE INDEX idx_recipes_category ON recipes(category);

-- ============================================================
-- Recipe translations (§3.1 multi-language)
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_translations (
  id          TEXT PRIMARY KEY,
  recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  locale      TEXT NOT NULL,
  title       TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  tools       TEXT NOT NULL DEFAULT '',
  tips        TEXT NOT NULL DEFAULT '',
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(recipe_id, locale)
);

-- ============================================================
-- Ingredients
-- ============================================================
CREATE TABLE IF NOT EXISTS ingredients (
  id         TEXT PRIMARY KEY,
  recipe_id  TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  amount     REAL,
  unit       TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_ingredients_recipe ON ingredients(recipe_id);

-- ============================================================
-- Steps
-- ============================================================
CREATE TABLE IF NOT EXISTS steps (
  id           TEXT PRIMARY KEY,
  recipe_id    TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  description  TEXT NOT NULL,
  step_type    TEXT NOT NULL DEFAULT 'active_cook' CHECK (step_type IN ('prep', 'active_cook')),
  time_minutes INTEGER,
  image        TEXT,                            -- R2 key
  video        TEXT,                            -- R2 key
  sort_order   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_steps_recipe ON steps(recipe_id);

-- ============================================================
-- Ingredient vocabulary (per user, for tag autocomplete)
-- ============================================================
CREATE TABLE IF NOT EXISTS ingredient_vocab (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, name)
);

-- ============================================================
-- Custom categories (per user; supplements the predefined list, §3.1)
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
-- Collections (§3.3)
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
-- Collection sharing (for visibility = 'shared', §3.3)
-- ============================================================
CREATE TABLE IF NOT EXISTS collection_shares (
  id            TEXT PRIMARY KEY,
  collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  shared_with   TEXT NOT NULL,                 -- Clerk user ID
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(collection_id, shared_with)
);

-- ============================================================
-- Shopping list (§3.8)
-- ============================================================
CREATE TABLE IF NOT EXISTS shopping_list (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id  TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  added_at   TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, recipe_id)
);

-- ============================================================
-- Meal plan (§3.9)
-- ============================================================
CREATE TABLE IF NOT EXISTS meal_plan (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date       TEXT NOT NULL,                    -- YYYY-MM-DD
  meal_type  TEXT NOT NULL DEFAULT 'other' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
  recipe_id  TEXT REFERENCES recipes(id) ON DELETE SET NULL,
  note       TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_meal_plan_user_date ON meal_plan(user_id, date);
