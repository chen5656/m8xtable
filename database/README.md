# M8x Table — Database (Cloudflare D1)

Single shared D1 database for all users (multi-tenant by `owner_user_id`).

## Setup

```bash
# Create the D1 database
npx wrangler d1 create m8x-table-db

# Run migrations
npx wrangler d1 migrations apply m8x-table-db --local   # local dev
npx wrangler d1 migrations apply m8x-table-db --remote  # production
```

## Migrations

All migrations live in `migrations/`. They are applied in order by filename prefix.

| Migration | Description |
|-----------|-------------|
| `0001_initial.sql` | Full initial schema: users, recipes, ingredients, steps, collections, shopping list, meal plan, books, share links, stars |
| `0002_m8x_updates.sql` | Add `is_draft`, `tools`, `tips` to recipes; `tools`/`tips` to recipe_translations; `is_pinned` to collections; custom_categories table |

## Key design decisions

- **Single database** for all users (multi-tenant by `owner_user_id`).
- **Soft delete** for recipes (`is_deleted` + `deleted_at`); auto-purge after 30 days (future cleanup script).
- **Draft model**: recipes are `is_draft = 1` until the user taps Save; drafts stored on-device only.
- **JSON arrays** stored as TEXT for tags (parsed at application layer).
- **R2 keys** stored as TEXT references for all media files.
- **Clerk user IDs** used as primary keys in the `users` table.

## Table overview

| Table | Purpose |
|-------|---------|
| `users` | App profile; auth handled by Clerk. Includes token quota for AI page generation. |
| `recipes` | Core recipe data; soft-delete; draft model; fork tracking |
| `recipe_translations` | Per-locale title, description, tools, tips |
| `ingredients` | Recipe ingredients with amount, unit, sort order |
| `steps` | Recipe steps with type (prep/active_cook), time, images, video |
| `ingredient_vocab` | Per-user ingredient name vocabulary for autocomplete |
| `collections` | User-created recipe groups; visibility (private/shared/public); pinnable |
| `collection_recipes` | M:M join: collections ↔ recipes |
| `collection_shares` | Specific users a collection is shared with |
| `custom_categories` | Per-user custom recipe categories |
| `recipe_pages` | AI-generated HTML recipe pages (custom layout) |
| `shopping_list` | Recipes added to user's shopping list |
| `meal_plan` | Calendar entries (recipe or free-text note per date/meal slot) |
| `books` | EPUB book export jobs (Premium tier) |
| `book_chapters` | Collection-level chapters within a book |
| `share_links` | Public share links for recipes (with optional expiry) |
| `stars` | User ↔ recipe star (like) relationship |
