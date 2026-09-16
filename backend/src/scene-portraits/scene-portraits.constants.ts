// Adjustable defaults, not locked-in product decisions.
export const CANDIDATE_COUNT = 4;
export const MAX_GENERATION_ATTEMPTS = 3; // 1 full attempt + 2 regenerations
export const VIDEO_DURATION_SECONDS = 5;
export const IMAGE_SIZE = '1024x1024'; // 1:1 — fits the circular observation window's bounding box
export const SCENE_TEXT_MAX_LENGTH = 200;
export const VIDEO_POLL_INTERVAL_MS = 4000;
export const MAX_VIDEO_POLL_ATTEMPTS = 45; // ~3 minute ceiling on the vendor task
