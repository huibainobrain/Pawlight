import fs from 'fs';

export interface ManifestRow {
  caseId: string;
  sampleId: string;
  modelKey: string;
  modelVersion: string;
  round: string;
  outputPath: string;
  status: string;
  durationSeconds: string;
  costEstimate: string;
  error: string;
  timestampIso: string;
}

// Minimal RFC4180-ish CSV parser matching exactly what run-eval.ts's
// csvEscape produces (quoted fields, "" for an embedded quote) - not a
// general-purpose CSV library, since the schema here is fixed and small.
export function parseManifest(manifestPath: string): ManifestRow[] {
  const text = fs.readFileSync(manifestPath, 'utf8');
  const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
  const [, ...dataLines] = lines; // drop header
  return dataLines.map((line) => {
    const fields = parseCsvLine(line);
    const [
      caseId,
      sampleId,
      modelKey,
      modelVersion,
      round,
      outputPath,
      status,
      durationSeconds,
      costEstimate,
      error,
      timestampIso,
    ] = fields;
    return {
      caseId,
      sampleId,
      modelKey,
      modelVersion,
      round,
      outputPath,
      status,
      durationSeconds,
      costEstimate,
      error,
      timestampIso,
    };
  });
}

function parseCsvLine(line: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (inQuotes) {
      if (c === '"' && line[i + 1] === '"') {
        current += '"';
        i++;
      } else if (c === '"') {
        inQuotes = false;
      } else {
        current += c;
      }
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ',') {
      fields.push(current);
      current = '';
    } else {
      current += c;
    }
  }
  fields.push(current);
  return fields;
}
