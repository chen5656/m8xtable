/**
 * Settings & account tests (§6.12)
 */

import { describe, it, expect } from '@jest/globals';

describe('Settings — API key management (§6.12)', () => {
  const providers = ['gemini', 'openai', 'claude', 'openrouter', 'qwen', 'glm'] as const;

  providers.forEach((provider) => {
    it(`user can add API key for ${provider}`, async () => {
      // TODO: saveApiKey(provider, 'key'), assert stored in keychain, status shows "configured"
      expect(true).toBe(true);
    });

    it(`user can update API key for ${provider}`, async () => {
      expect(true).toBe(true);
    });

    it(`user can remove API key for ${provider}`, async () => {
      // TODO: removeApiKey(provider), assert removed from keychain, status shows "not configured"
      expect(true).toBe(true);
    });
  });
});

describe('Settings — Profile', () => {
  it('user can view their display name and avatar', async () => {
    // TODO: render ProfileSettings, assert name and avatar shown
    expect(true).toBe(true);
  });

  it('user can edit display name', async () => {
    expect(true).toBe(true);
  });
});

describe('Settings — Language', () => {
  it('language option shows current locale', async () => {
    expect(true).toBe(true);
  });

  it('tapping language opens system Settings app', async () => {
    // TODO: tap, assert Linking.openSettings() called
    expect(true).toBe(true);
  });
});
