import path from 'path';

export const ROUNDS_PER_CASE = 2;

export const PETS_DIR = path.join(__dirname, '..', 'pets');
export const OUTPUT_DIR = path.join(__dirname, '..', 'output');
export const MANIFEST_PATH = path.join(__dirname, '..', 'manifest.csv');
export const PROMPT_TEMPLATE_PATH = path.join(
  __dirname,
  '..',
  'prompt-template.txt',
);
export const SCENE_PLACEHOLDER = '{用户输入的场景描述}';

export const TEST_CASES_SHEET_NAME = '测试用例';
export const SCORING_SHEET_NAME = '单图评分';

// Max concurrent in-flight requests per model - keep conservative until each
// vendor's actual rate limit is known; lower this if you see 429s.
export const CONCURRENCY_PER_MODEL: Record<string, number> = {
  seedream: 3,
  nanobanana: 3,
  flux: 2,
};

// Estimated RMB cost per generated image. Fill in real numbers once known
// (from each vendor's console/pricing page) - left null means "unknown",
// and the manifest/spreadsheet will record it as blank rather than 0, so it
// never gets silently mistaken for "free."
export const PRICE_PER_IMAGE_RMB: Record<string, number | null> = {
  seedream: null,
  nanobanana: null,
  flux: null,
};

export const RETRY_ATTEMPTS = 3;
export const RETRY_BASE_DELAY_MS = 2000;
