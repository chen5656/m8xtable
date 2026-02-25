-- M8x Table — Schema updates (migration from Canvas & Clove base)
-- Adds missing fields from Plan.md and todo.later.md

-- ============================================================
-- Recipes: add missing fields from Plan.md
-- ============================================================

-- is_draft: all new/in-progress recipes are drafts until the user taps Save (§6.2)
ALTER TABLE recipes ADD COLUMN is_draft INTEGER NOT NULL DEFAULT 0;

-- tools: tools/equipment required for the recipe (§3.1)
ALTER TABLE recipes ADD COLUMN tools TEXT NOT NULL DEFAULT '';

-- tips: tips/notes for the recipe (§3.1)
ALTER TABLE recipes ADD COLUMN tips TEXT NOT NULL DEFAULT '';

CREATE INDEX idx_recipes_draft ON recipes(is_draft);

-- ============================================================
-- Recipe translations: add translated tools and tips
-- ============================================================
ALTER TABLE recipe_translations ADD COLUMN tools TEXT NOT NULL DEFAULT '';
ALTER TABLE recipe_translations ADD COLUMN tips TEXT NOT NULL DEFAULT '';

-- ============================================================
-- Collections: add is_pinned for pin/unpin operation (§3.3)
-- ============================================================
ALTER TABLE collections ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0;

-- ============================================================
-- Custom categories (per user, §3.1 "predefined + custom")
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
