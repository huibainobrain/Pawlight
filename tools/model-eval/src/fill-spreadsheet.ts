import 'dotenv/config';
import path from 'path';
import ExcelJS from 'exceljs';
import { MANIFEST_PATH, SCORING_SHEET_NAME } from './config';
import { parseManifest } from './parse-manifest';

// Column letters in 单图评分, per its header row (see docs comment below for
// the full layout) - only these are written; every scoring/formula column
// is left untouched.
const COL = {
  caseId: 'B',
  sampleId: 'C',
  model: 'D',
  modelVersion: 'E',
  round: 'F',
  resultFile: 'G',
  durationSeconds: 'AU',
  costEstimate: 'AV',
  notes: 'AW',
} as const;

async function main() {
  const workbookPath = process.env.EVAL_WORKBOOK_PATH;
  if (!workbookPath) {
    throw new Error('EVAL_WORKBOOK_PATH is not set (see .env.example)');
  }

  const rows = parseManifest(MANIFEST_PATH);
  if (rows.length === 0) {
    throw new Error(`${MANIFEST_PATH} has no rows - run "npm run generate" first.`);
  }

  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(workbookPath);
  const sheet = workbook.getWorksheet(SCORING_SHEET_NAME);
  if (!sheet) {
    throw new Error(`Workbook has no "${SCORING_SHEET_NAME}" sheet`);
  }

  rows.forEach((row, index) => {
    const rowNumber = index + 2; // row 1 is the header; 记录编号 (col A) is
    // left as-is (R001, R002, ... already pre-filled in the template).
    sheet.getCell(`${COL.caseId}${rowNumber}`).value = row.caseId;
    sheet.getCell(`${COL.sampleId}${rowNumber}`).value = row.sampleId;
    sheet.getCell(`${COL.model}${rowNumber}`).value = row.modelKey;
    sheet.getCell(`${COL.modelVersion}${rowNumber}`).value = row.modelVersion;
    sheet.getCell(`${COL.round}${rowNumber}`).value = Number(row.round);

    if (row.status === 'ok' || row.status === 'skipped') {
      const absPath = path.resolve(row.outputPath);
      sheet.getCell(`${COL.resultFile}${rowNumber}`).value = {
        text: row.outputPath,
        hyperlink: `file://${absPath}`,
      };
    }
    if (row.durationSeconds) {
      sheet.getCell(`${COL.durationSeconds}${rowNumber}`).value = Number(
        row.durationSeconds,
      );
    }
    if (row.costEstimate) {
      sheet.getCell(`${COL.costEstimate}${rowNumber}`).value = Number(
        row.costEstimate,
      );
    }
    if (row.status === 'error') {
      sheet.getCell(`${COL.notes}${rowNumber}`).value =
        `生成失败，未写入结果图: ${row.error}`;
    }
  });

  const outPath = process.argv[2] ?? defaultOutputPath(workbookPath);
  await workbook.xlsx.writeFile(outPath);
  console.log(`Wrote ${rows.length} row(s) into "${SCORING_SHEET_NAME}".`);
  console.log(`Saved to: ${outPath}`);
  console.log(
    'This is a separate file - review it, then replace your working copy yourself once you are happy with it.',
  );
}

function defaultOutputPath(workbookPath: string): string {
  const ext = path.extname(workbookPath);
  const base = workbookPath.slice(0, -ext.length);
  return `${base}_filled${ext}`;
}

main().catch((err: unknown) => {
  console.error('[fill-spreadsheet] FAILED:', err instanceof Error ? err.stack : err);
  process.exit(1);
});
