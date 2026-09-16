// Per docs/11_ai_scene_portrait_api_research.md §9, simplified: no separate
// "cheap model describes the pet first" pre-processing step this round —
// identity lock is a fixed, generic instruction instead.

const STYLE_PREFIX =
  'soft warm anime illustration, gentle pastel palette, painterly light, ' +
  'Studio-Ghibli-adjacent, no harsh outlines.';

const IDENTITY_LOCK =
  "Preserve the pet's exact breed, body shape, fur color and markings, ear shape, " +
  'eye color, and any distinctive features visible in the reference photo. ' +
  'Keep the face structure and markings unchanged.';

const NEGATIVE_CONSTRAINTS =
  'Do not change breed, do not restyle markings, do not alter eye color, ' +
  'no text, no watermark, no human faces.';

export function buildScenePortraitPrompt(sceneText: string): string {
  const scene = sceneText.trim() || 'resting peacefully in a soft, sunlit spot';
  return [STYLE_PREFIX, IDENTITY_LOCK, `Scene: ${scene}.`, NEGATIVE_CONSTRAINTS].join(' ');
}

// One fixed "gentle idle loop" motion prompt — no per-scene-category taxonomy
// this round; revisit if the generic version doesn't loop convincingly.
export function buildMotionPrompt(): string {
  return (
    'Gentle idle loop, about 5 seconds: soft breathing motion, an occasional slow ' +
    'blink, subtle ambient movement in the background (light flicker, fur or fabric ' +
    'sway). No camera movement, no scene change. The first and last frame should ' +
    'match closely so the clip can loop seamlessly.'
  );
}
