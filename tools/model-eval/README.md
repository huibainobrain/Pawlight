# Scene-portrait model evaluation

One-off batch runner for comparing 3 candidate image-generation models
(Seedream / Nano Banana / Flux) against the scoring workbook
`Pawlight_图片生成模型评测表_最终执行版.xlsx`. Not part of the Pawlight app -
this never ships, never runs in CI, and its output (60 generated images) is
not committed.

Plan: 10 pets x 1 frozen prompt template (with a per-pet scene substituted
in) x 3 models x 2 rounds = 60 images.

## Setup

```bash
cd tools/model-eval
npm install
cp .env.example .env
```

Fill in `.env`:
- `SEEDREAM_API_KEY` / `NANOBANANA_API_KEY` / `FLUX_API_KEY` - real keys,
  never commit this file (gitignored already).
- `*_MODEL_ID` / `FLUX_ENDPOINT` - the exact model/endpoint strings once
  confirmed; see the comment at the top of each file under
  `src/providers/` for what each was written against and what to
  double-check on first real run.
- `EVAL_WORKBOOK_PATH` - absolute path to your local copy of the scoring
  workbook (keep it outside the repo, e.g. in `~/Downloads/`).

## Inputs you provide

1. **Reference photos** - `pets/<sampleId>/*.jpg` (2-3 photos per pet, same
   set reused across every model). See `pets/README.md`.
2. **Scene text** - fill in the 用户原始场景需求 column (C) of the workbook's
   测试用例 sheet, one row per pet (用例编号 + 样本编号 already listed as
   C01/P01 ... C10/P10). This gets substituted into
   `prompt-template.txt`'s `{用户输入的场景描述}` placeholder - the rest of
   the prompt is frozen and identical for all 60 generations.

## Running

```bash
npm run generate
```

Expands into 60 jobs (10 pets x 3 models x 2 rounds), runs them with bounded
per-model concurrency (`src/config.ts`'s `CONCURRENCY_PER_MODEL` - lower it
if you see 429s), retries transient failures a few times, and writes:

- `output/<sampleId>_<modelKey>_r<round>.png` - the generated images.
- `manifest.csv` - one row per job: status, duration, cost estimate, error
  if any.

**Resumable**: if a run is interrupted or some jobs fail, just run
`npm run generate` again - any job whose output file already exists is
skipped, so you only pay for/wait on what's still missing.

## Filling the scoring workbook

```bash
npm run fill-sheet
```

Reads `manifest.csv` and writes 用例编号/样本编号/模型/模型版本/生成轮次/
结果文件(as a clickable file link)/生成耗时/单次成本 into the workbook's
单图评分 sheet (rows 2+, in manifest order) - every scoring column and every
formula column is left untouched. A failed job still gets a row, with the
error noted in 备注 instead of a result file, so the row count always
matches what you expect.

This writes to a **new** file (`<name>_filled.xlsx` next to the original,
or pass a path as the first argument) rather than overwriting your working
copy - review it, then replace your working copy yourself.

## Known limitations

- Flux's direct BFL API only takes one reference image per request (no
  confirmed multi-image endpoint at research time) - if a pet has 2-3
  reference photos, only the first is sent to Flux; Seedream and Nano
  Banana receive all of them.
- The Nano Banana and Flux adapters were written from vendor docs research,
  not validated against a real key yet (unlike the Seedream adapter, which
  reuses the already-validated shape from
  `backend/src/scene-portraits/providers/ark-image-gen.provider.ts`) - the
  first real run is the actual validation; expect to adjust field names/
  endpoint paths if either vendor's API has moved since.
- Per-image cost (`单次成本`) is `null`/blank until you fill in real prices
  in `src/config.ts`'s `PRICE_PER_IMAGE_RMB` - nothing is guessed.
