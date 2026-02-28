-- m8xtable — Migration 0003: Single-Language Content
--
-- Changes:
--   1. Restore translatable columns on recipes, ingredients, steps.
--   2. Backfill from translation tables, preferring the owner's locale.
--   3. Drop translation tables (recipe_translations, ingredient_translations, step_translations).

-- ============================================================
-- 1. Recipes: restore columns
-- ============================================================
ALTER TABLE recipes ADD COLUMN title TEXT NOT NULL DEFAULT '';
ALTER TABLE recipes ADD COLUMN description TEXT NOT NULL DEFAULT '';
ALTER TABLE recipes ADD COLUMN tools TEXT NOT NULL DEFAULT '';
ALTER TABLE recipes ADD COLUMN tips TEXT NOT NULL DEFAULT '';

-- ============================================================
-- 2. Ingredients: restore columns
-- ============================================================
ALTER TABLE ingredients ADD COLUMN name TEXT NOT NULL DEFAULT '';
ALTER TABLE ingredients ADD COLUMN unit TEXT NOT NULL DEFAULT '';

-- ============================================================
-- 3. Steps: restore columns
-- ============================================================
ALTER TABLE steps ADD COLUMN description TEXT NOT NULL DEFAULT '';

-- ============================================================
-- 4. Backfill from translation tables (best-effort)
-- ============================================================
UPDATE recipes
SET
  title = COALESCE(
    (SELECT rt.title
     FROM recipe_translations rt
     WHERE rt.recipe_id = recipes.id
       AND rt.locale = (SELECT u.locale FROM users u WHERE u.id = recipes.owner_user_id)
     LIMIT 1),
    (SELECT rt.title FROM recipe_translations rt WHERE rt.recipe_id = recipes.id LIMIT 1),
    title
  ),
  description = COALESCE(
    (SELECT rt.description
     FROM recipe_translations rt
     WHERE rt.recipe_id = recipes.id
       AND rt.locale = (SELECT u.locale FROM users u WHERE u.id = recipes.owner_user_id)
     LIMIT 1),
    (SELECT rt.description FROM recipe_translations rt WHERE rt.recipe_id = recipes.id LIMIT 1),
    description
  ),
  tools = COALESCE(
    (SELECT rt.tools
     FROM recipe_translations rt
     WHERE rt.recipe_id = recipes.id
       AND rt.locale = (SELECT u.locale FROM users u WHERE u.id = recipes.owner_user_id)
     LIMIT 1),
    (SELECT rt.tools FROM recipe_translations rt WHERE rt.recipe_id = recipes.id LIMIT 1),
    tools
  ),
  tips = COALESCE(
    (SELECT rt.tips
     FROM recipe_translations rt
     WHERE rt.recipe_id = recipes.id
       AND rt.locale = (SELECT u.locale FROM users u WHERE u.id = recipes.owner_user_id)
     LIMIT 1),
    (SELECT rt.tips FROM recipe_translations rt WHERE rt.recipe_id = recipes.id LIMIT 1),
    tips
  );

UPDATE ingredients
SET
  name = COALESCE(
    (SELECT it.name
     FROM ingredient_translations it
     WHERE it.ingredient_id = ingredients.id
       AND it.locale = (
         SELECT u.locale
         FROM users u
         JOIN recipes r ON r.owner_user_id = u.id
         WHERE r.id = ingredients.recipe_id
         LIMIT 1
       )
     LIMIT 1),
    (SELECT it.name FROM ingredient_translations it WHERE it.ingredient_id = ingredients.id LIMIT 1),
    name
  ),
  unit = COALESCE(
    (SELECT it.unit
     FROM ingredient_translations it
     WHERE it.ingredient_id = ingredients.id
       AND it.locale = (
         SELECT u.locale
         FROM users u
         JOIN recipes r ON r.owner_user_id = u.id
         WHERE r.id = ingredients.recipe_id
         LIMIT 1
       )
     LIMIT 1),
    (SELECT it.unit FROM ingredient_translations it WHERE it.ingredient_id = ingredients.id LIMIT 1),
    unit
  );

UPDATE steps
SET
  description = COALESCE(
    (SELECT st.description
     FROM step_translations st
     WHERE st.step_id = steps.id
       AND st.locale = (
         SELECT u.locale
         FROM users u
         JOIN recipes r ON r.owner_user_id = u.id
         WHERE r.id = steps.recipe_id
         LIMIT 1
       )
     LIMIT 1),
    (SELECT st.description FROM step_translations st WHERE st.step_id = steps.id LIMIT 1),
    description
  );

-- ============================================================
-- 5. Drop translation tables
-- ============================================================
DROP TABLE IF EXISTS recipe_translations;
DROP TABLE IF EXISTS ingredient_translations;
DROP TABLE IF EXISTS step_translations;
