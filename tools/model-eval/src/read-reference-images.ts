import fs from 'fs';
import path from 'path';
import { PETS_DIR } from './config';
import { ReferenceImage } from './types';

const MIME_BY_EXT: Record<string, string> = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

// Reference photos live in pets/<sampleId>/ - 2-3 fixed images per pet, the
// same set reused across every model/round for that pet (see 使用说明:
// "同一个测试用例在不同模型中必须使用同一组参考图"). Any image file directly
// inside that folder is picked up; subfolders and non-image files are
// ignored.
export function readReferenceImages(sampleId: string): ReferenceImage[] {
  const dir = path.join(PETS_DIR, sampleId);
  if (!fs.existsSync(dir)) {
    throw new Error(
      `No reference images found for ${sampleId} - expected a folder at ${dir}`,
    );
  }
  const files = fs
    .readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => entry.name)
    .filter((name) => MIME_BY_EXT[path.extname(name).toLowerCase()])
    .sort();

  if (files.length === 0) {
    throw new Error(`${dir} has no image files (.jpg/.jpeg/.png/.webp)`);
  }

  return files.map((name) => {
    const ext = path.extname(name).toLowerCase();
    return {
      buffer: fs.readFileSync(path.join(dir, name)),
      mimeType: MIME_BY_EXT[ext],
    };
  });
}
