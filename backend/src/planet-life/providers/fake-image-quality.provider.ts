import { Injectable } from '@nestjs/common';
import {
  ImageQualityProvider,
  ImageQualityCheckInput,
} from './image-quality.provider';
import { QualityCheckResult } from './image-quality.provider';

@Injectable()
export class FakeImageQualityProvider implements ImageQualityProvider {
  check(_input: ImageQualityCheckInput): Promise<QualityCheckResult> {
    return Promise.resolve({ pass: true });
  }
}
