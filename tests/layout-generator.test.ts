import { describe, it, expect } from '@jest/globals';
import { updateRecipeListLayout, getTodaySeed } from '../lib/layout-generator';

describe('updateRecipeListLayout', () => {
  it('returns empty array for 0 items', () => {
    expect(updateRecipeListLayout(3, 0, 20260308)).toEqual([]);
  });

  it('returns correct number of items', () => {
    const layout = updateRecipeListLayout(3, 16, 20260308);
    expect(layout).toHaveLength(16);
  });

  it('is deterministic with same seed', () => {
    const a = updateRecipeListLayout(3, 16, 20260308);
    const b = updateRecipeListLayout(3, 16, 20260308);
    expect(a).toEqual(b);
  });

  it('produces different layouts with different seeds', () => {
    const a = updateRecipeListLayout(3, 16, 20260308);
    const b = updateRecipeListLayout(3, 16, 20260309);
    expect(a).not.toEqual(b);
  });

  it('all colSpan values fit within column count', () => {
    for (const cols of [3, 4, 6] as const) {
      const layout = updateRecipeListLayout(cols, 16, 99);
      for (const item of layout) {
        expect(item[0]).toBeLessThanOrEqual(cols);
        expect(item[0]).toBeGreaterThan(0);
        expect(item[1]).toBeGreaterThan(0);
      }
    }
  });
});

describe('getTodaySeed', () => {
  it('returns a number in YYYYMMDD format', () => {
    const seed = getTodaySeed();
    expect(seed).toBeGreaterThan(20200101);
    expect(seed).toBeLessThan(21000101);
  });
});
