import ExcelJS from 'exceljs';
import { TEST_CASES_SHEET_NAME } from './config';
import { TestCase } from './types';

// Reads the 测试用例 sheet: 用例编号(A) / 样本编号(B) / 用户原始场景需求(C).
// The sheet also has 核心环境/动作状态/关键场景元素/... breakdown columns
// (D onward) - those are for the human reviewer's reference when scoring
// 场景还原, not needed here; only the raw scene text (C) goes into the prompt.
export async function readTestCases(workbookPath: string): Promise<TestCase[]> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(workbookPath);
  const sheet = workbook.getWorksheet(TEST_CASES_SHEET_NAME);
  if (!sheet) {
    throw new Error(
      `Workbook has no "${TEST_CASES_SHEET_NAME}" sheet - is EVAL_WORKBOOK_PATH pointing at the right file?`,
    );
  }

  const cases: TestCase[] = [];
  const missingScene: string[] = [];

  sheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
    if (rowNumber === 1) return; // header
    const caseId = cellText(row.getCell(1));
    const sampleId = cellText(row.getCell(2));
    const sceneText = cellText(row.getCell(3));
    if (!caseId && !sampleId) return; // blank trailing row

    if (!sceneText) {
      missingScene.push(caseId || sampleId || `row ${rowNumber}`);
      return;
    }
    cases.push({ caseId, sampleId, sceneText });
  });

  if (missingScene.length > 0) {
    console.warn(
      `[read-test-cases] Skipping ${missingScene.length} row(s) with no 用户原始场景需求 filled in yet: ${missingScene.join(', ')}`,
    );
  }
  if (cases.length === 0) {
    throw new Error(
      `No usable rows found in "${TEST_CASES_SHEET_NAME}" - fill in 用户原始场景需求 for at least one pet first.`,
    );
  }
  return cases;
}

function cellText(cell: ExcelJS.Cell): string {
  const value = cell.value;
  if (value == null) return '';
  if (typeof value === 'object' && 'richText' in value) {
    return value.richText.map((part) => part.text).join('');
  }
  return String(value).trim();
}
