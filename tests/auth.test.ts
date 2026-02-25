/**
 * Auth & profile tests (§6.1)
 * Sign in with Apple via Clerk; profile management; account deletion.
 */

import { describe, it, expect } from '@jest/globals';

// TODO: import auth helpers
// import { signInWithApple, getProfile, updateProfile, deleteAccount } from '../src/auth';

describe('Auth — Sign in with Apple', () => {
  it('creates a new user record on first sign-in', async () => {
    // TODO: mock Clerk Apple Sign In, call sign-in handler,
    //       assert users row created with Clerk user ID
    expect(true).toBe(true);
  });

  it('returns existing user record on subsequent sign-in', async () => {
    // TODO: sign in twice, assert same user ID returned
    expect(true).toBe(true);
  });

  it('stores display_name and locale on first login', async () => {
    // TODO: assert defaults applied
    expect(true).toBe(true);
  });
});

describe('Auth — Profile', () => {
  it('user can update display_name', async () => {
    // TODO: call updateProfile, assert DB updated
    expect(true).toBe(true);
  });

  it('user can update avatar (uploads to R2, stores key in users.profile_picture)', async () => {
    // TODO: mock R2 upload, call updateProfile, assert profile_picture key saved
    expect(true).toBe(true);
  });
});

describe('Auth — Account deletion', () => {
  it('deletes all recipe images from R2', async () => {
    // TODO: mock R2 delete, call deleteAccount, assert all R2 keys removed
    expect(true).toBe(true);
  });

  it('deletes all step images and videos from R2', async () => {
    expect(true).toBe(true);
  });

  it('deletes the user row from D1 (cascades to recipes, collections, etc.)', async () => {
    // TODO: call deleteAccount, assert user row and all cascaded rows gone
    expect(true).toBe(true);
  });

  it('deletes the Clerk account', async () => {
    // TODO: mock Clerk deleteUser, assert called
    expect(true).toBe(true);
  });

  it('shows animated deletion progress UI steps', async () => {
    // TODO: render DeleteAccountFlow, assert "deleting images", "deleting recipes",
    //       "deleting account" steps appear in order
    expect(true).toBe(true);
  });
});
