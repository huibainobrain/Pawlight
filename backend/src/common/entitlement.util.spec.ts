import {
  albumPhotoLimit,
  FREE_PHOTO_LIMIT,
  PAID_PHOTO_LIMIT,
} from './entitlement.util';

describe('albumPhotoLimit', () => {
  it('returns the FREE default when there is no entitlement', () => {
    expect(albumPhotoLimit(null)).toBe(FREE_PHOTO_LIMIT);
    expect(albumPhotoLimit(undefined)).toBe(FREE_PHOTO_LIMIT);
  });

  it('returns the FREE default for a FREE tier with no explicit photoLimit', () => {
    expect(albumPhotoLimit({ tier: 'FREE', photoLimit: null })).toBe(
      FREE_PHOTO_LIMIT,
    );
  });

  it('returns the PAID default for a PAID tier with no explicit photoLimit', () => {
    expect(albumPhotoLimit({ tier: 'PAID', photoLimit: null })).toBe(
      PAID_PHOTO_LIMIT,
    );
  });

  it('prefers an explicit positive photoLimit over the tier default', () => {
    expect(albumPhotoLimit({ tier: 'FREE', photoLimit: 25 })).toBe(25);
    expect(albumPhotoLimit({ tier: 'PAID', photoLimit: 3 })).toBe(3);
  });

  it('falls back to the tier default when photoLimit is 0 or negative', () => {
    expect(albumPhotoLimit({ tier: 'FREE', photoLimit: 0 })).toBe(
      FREE_PHOTO_LIMIT,
    );
    expect(albumPhotoLimit({ tier: 'PAID', photoLimit: -1 })).toBe(
      PAID_PHOTO_LIMIT,
    );
  });
});
