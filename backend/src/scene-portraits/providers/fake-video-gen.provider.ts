import { Injectable } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import { randomUUID } from 'crypto';
import {
  VideoGenProvider,
  SubmitImageToVideoInput,
  VideoGenTaskResult,
} from './video-gen.provider';

// Reports "pending" for this many polls before "succeeded", so the iOS
// polling loop's loading state is actually exercised during local testing
// instead of resolving instantly.
const PENDING_POLLS_BEFORE_DONE = 2;

// Selected via SCENE_PORTRAIT_VIDEO_PROVIDER=fake — zero network calls, reads
// a small bundled fixture instead. See fixtures/fake-observation-loop.mp4.
@Injectable()
export class FakeVideoGenProvider implements VideoGenProvider {
  private pollCounts = new Map<string, number>();

  submitImageToVideo(
    _input: SubmitImageToVideoInput,
  ): Promise<{ providerTaskId: string }> {
    const providerTaskId = randomUUID();
    this.pollCounts.set(providerTaskId, 0);
    return Promise.resolve({ providerTaskId });
  }

  pollTask(providerTaskId: string): Promise<VideoGenTaskResult> {
    const count = (this.pollCounts.get(providerTaskId) ?? 0) + 1;
    this.pollCounts.set(providerTaskId, count);
    if (count < PENDING_POLLS_BEFORE_DONE) {
      return Promise.resolve({ status: 'pending' });
    }
    const buffer = readFileSync(
      join(__dirname, 'fixtures', 'fake-observation-loop.mp4'),
    );
    return Promise.resolve({
      status: 'succeeded',
      video: { buffer, contentType: 'video/mp4' },
    });
  }
}
