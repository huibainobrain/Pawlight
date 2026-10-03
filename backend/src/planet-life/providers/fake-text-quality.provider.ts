import { Injectable } from '@nestjs/common';
import {
  TextQualityProvider,
  TextQualityCheckInput,
} from './text-quality.provider';
import { QualityCheckResult } from './image-quality.provider';

@Injectable()
export class FakeTextQualityProvider implements TextQualityProvider {
  check(_input: TextQualityCheckInput): Promise<QualityCheckResult> {
    return Promise.resolve({ pass: true });
  }
}
