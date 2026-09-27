export interface ReferenceImage {
  buffer: Buffer;
  mimeType: string;
}

export interface GeneratedImage {
  buffer: Buffer;
  contentType: string;
}

// One candidate model under test. `key` must be stable (used in output
// filenames and the spreadsheet's 模型 column); `modelVersion` is whatever
// string identifies the exact model/endpoint used, logged into the
// spreadsheet's 模型版本 column so a later run with a different version is
// distinguishable.
export interface EvalImageProvider {
  readonly key: string;
  readonly modelVersion: string;
  generate(input: {
    referenceImages: ReferenceImage[];
    prompt: string;
  }): Promise<GeneratedImage>;
}

// One row read from the workbook's 测试用例 sheet.
export interface TestCase {
  caseId: string; // 用例编号, e.g. "C01"
  sampleId: string; // 样本编号, e.g. "P01"
  sceneText: string; // 用户原始场景需求 - substituted into the prompt template
}

export interface EvalJob {
  testCase: TestCase;
  modelKey: string;
  round: number; // 1-based
  outputPath: string;
}

export interface JobOutcome {
  job: EvalJob;
  status: 'ok' | 'error' | 'skipped';
  modelVersion: string;
  durationSeconds: number;
  costEstimate: number | null;
  error: string | null;
  timestampIso: string;
}
