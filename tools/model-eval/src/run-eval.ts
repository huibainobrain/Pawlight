import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import pLimit from 'p-limit';
import {
  CONCURRENCY_PER_MODEL,
  MANIFEST_PATH,
  OUTPUT_DIR,
  PRICE_PER_IMAGE_RMB,
  PROMPT_TEMPLATE_PATH,
  ROUNDS_PER_CASE,
  SCENE_PLACEHOLDER,
} from './config';
import { readTestCases } from './read-test-cases';
import { readReferenceImages } from './read-reference-images';
import { withRetry } from './retry';
import { EvalImageProvider, EvalJob, JobOutcome, TestCase } from './types';
import { SeedreamProvider } from './providers/seedream.provider';
import { NanoBananaProvider } from './providers/nanobanana.provider';
import { FluxProvider } from './providers/flux.provider';

function buildProviders(): EvalImageProvider[] {
  return [new SeedreamProvider(), new NanoBananaProvider(), new FluxProvider()];
}

function buildPrompt(template: string, sceneText: string): string {
  if (!template.includes(SCENE_PLACEHOLDER)) {
    throw new Error(
      `prompt-template.txt does not contain the expected placeholder "${SCENE_PLACEHOLDER}"`,
    );
  }
  return template.replaceAll(SCENE_PLACEHOLDER, sceneText);
}

function outputPathFor(testCase: TestCase, modelKey: string, round: number) {
  return path.join(OUTPUT_DIR, `${testCase.sampleId}_${modelKey}_r${round}.png`);
}

function csvEscape(value: string | number | null): string {
  if (value === null) return '';
  const str = String(value);
  if (/[",\n]/.test(str)) return `"${str.replace(/"/g, '""')}"`;
  return str;
}

function appendManifestRow(outcome: JobOutcome) {
  const exists = fs.existsSync(MANIFEST_PATH);
  const header =
    'caseId,sampleId,modelKey,modelVersion,round,outputPath,status,durationSeconds,costEstimate,error,timestampIso\n';
  const row =
    [
      outcome.job.testCase.caseId,
      outcome.job.testCase.sampleId,
      outcome.job.modelKey,
      outcome.modelVersion,
      outcome.job.round,
      outcome.status === 'ok' ? outcome.job.outputPath : '',
      outcome.status,
      outcome.durationSeconds.toFixed(1),
      outcome.costEstimate,
      outcome.error,
      outcome.timestampIso,
    ]
      .map(csvEscape)
      .join(',') + '\n';
  fs.appendFileSync(MANIFEST_PATH, (exists ? '' : header) + row);
}

async function runJob(
  provider: EvalImageProvider,
  testCase: TestCase,
  round: number,
  prompt: string,
): Promise<JobOutcome> {
  const job: EvalJob = {
    testCase,
    modelKey: provider.key,
    round,
    outputPath: outputPathFor(testCase, provider.key, round),
  };

  if (fs.existsSync(job.outputPath)) {
    console.log(`[skip] ${job.outputPath} already exists`);
    return {
      job,
      status: 'skipped',
      modelVersion: provider.modelVersion,
      durationSeconds: 0,
      costEstimate: null,
      error: null,
      timestampIso: new Date().toISOString(),
    };
  }

  const referenceImages = readReferenceImages(testCase.sampleId);
  const label = `${testCase.sampleId}/${provider.key}/r${round}`;
  const start = Date.now();
  try {
    const result = await withRetry(
      () => provider.generate({ referenceImages, prompt }),
      label,
    );
    fs.writeFileSync(job.outputPath, result.buffer);
    const durationSeconds = (Date.now() - start) / 1000;
    console.log(`[ok]   ${label} -> ${job.outputPath} (${durationSeconds.toFixed(1)}s)`);
    return {
      job,
      status: 'ok',
      modelVersion: provider.modelVersion,
      durationSeconds,
      costEstimate: PRICE_PER_IMAGE_RMB[provider.key],
      error: null,
      timestampIso: new Date().toISOString(),
    };
  } catch (err) {
    const durationSeconds = (Date.now() - start) / 1000;
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[fail] ${label}: ${message}`);
    return {
      job,
      status: 'error',
      modelVersion: provider.modelVersion,
      durationSeconds,
      costEstimate: null,
      error: message,
      timestampIso: new Date().toISOString(),
    };
  }
}

async function main() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const template = fs.readFileSync(PROMPT_TEMPLATE_PATH, 'utf8');
  const workbookPath = process.env.EVAL_WORKBOOK_PATH;
  if (!workbookPath) {
    throw new Error('EVAL_WORKBOOK_PATH is not set (see .env.example)');
  }
  const testCases = await readTestCases(workbookPath);
  const providers = buildProviders();

  console.log(
    `Loaded ${testCases.length} test case(s); ${providers.length} model(s) x ${ROUNDS_PER_CASE} round(s) = ${
      testCases.length * providers.length * ROUNDS_PER_CASE
    } job(s) total.`,
  );

  const limiters = new Map(
    providers.map((p) => [p.key, pLimit(CONCURRENCY_PER_MODEL[p.key] ?? 2)]),
  );

  const outcomes: JobOutcome[] = [];
  const allJobs: Promise<void>[] = [];

  for (const testCase of testCases) {
    const prompt = buildPrompt(template, testCase.sceneText);
    for (const provider of providers) {
      const limit = limiters.get(provider.key)!;
      for (let round = 1; round <= ROUNDS_PER_CASE; round++) {
        allJobs.push(
          limit(async () => {
            const outcome = await runJob(provider, testCase, round, prompt);
            outcomes.push(outcome);
            appendManifestRow(outcome);
          }),
        );
      }
    }
  }

  await Promise.all(allJobs);

  const ok = outcomes.filter((o) => o.status === 'ok').length;
  const skipped = outcomes.filter((o) => o.status === 'skipped').length;
  const failed = outcomes.filter((o) => o.status === 'error').length;
  console.log(`\nDone. ok=${ok} skipped=${skipped} failed=${failed}`);
  console.log(`Manifest: ${MANIFEST_PATH}`);
  if (failed > 0) {
    console.log(
      'Re-run the same command to retry only the failed/missing jobs - already-succeeded outputs are skipped.',
    );
    process.exitCode = 1;
  }
}

main().catch((err: unknown) => {
  console.error('[run-eval] FAILED:', err instanceof Error ? err.stack : err);
  process.exit(1);
});
