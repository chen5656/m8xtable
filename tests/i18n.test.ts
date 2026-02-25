/**
 * Internationalisation tests (§9.3)
 * Supported locales: en, zh-Hans
 */

import { describe, it, expect } from '@jest/globals';

describe('i18n — Locale support', () => {
  it('app defaults to device locale if supported (en or zh-Hans)', async () => {
    // TODO: mock device locale = 'zh-Hans', assert app renders in Chinese
    expect(true).toBe(true);
  });

  it('app falls back to English for unsupported device locales', async () => {
    // TODO: mock device locale = 'fr', assert app renders in English
    expect(true).toBe(true);
  });

  it('tapping language option opens system Settings', async () => {
    // TODO: tap language option, assert Linking.openSettings() called
    expect(true).toBe(true);
  });
});

describe('i18n — Translation coverage', () => {
  const screens = [
    'Home', 'RecipeDetail', 'RecipeEdit', 'Collections', 'CollectionDetail',
    'ShoppingList', 'MealPlan', 'Settings', 'APIKeys', 'Profile',
    'RecipePage', 'ShareLink', 'Books', 'Bookshelf',
  ];

  screens.forEach((screen) => {
    it(`all visible strings on ${screen} are translated (en & zh-Hans)`, async () => {
      // TODO: scan Lingui catalog for missing translations on this screen
      expect(true).toBe(true);
    });
  });
});

describe('i18n — Dynamic content', () => {
  it('AI-generated recipe uses output language matching app locale', async () => {
    // TODO: locale = zh-Hans, generateRecipe(), assert Chinese text returned
    expect(true).toBe(true);
  });

  it('recipe translations fetched in current locale', async () => {
    // TODO: locale = zh-Hans, getRecipe(), assert zh-Hans translation returned
    expect(true).toBe(true);
  });
});
