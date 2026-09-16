export const VIDEO_GEN_PROVIDER = 'VIDEO_GEN_PROVIDER';

export interface GeneratedVideo {
  buffer: Buffer;
  contentType: string;
}

export interface SubmitImageToVideoInput {
  imageUrl: string;
  motionPrompt: string;
  durationSeconds: number;
}

export type VideoGenTaskResult =
  | { status: 'pending' }
  | { status: 'succeeded'; video: GeneratedVideo }
  | { status: 'failed'; errorMessage: string };

// Swappable behind SCENE_PORTRAIT_VIDEO_PROVIDER — see scene-portraits.module.ts.
// Both Ark/Seedance and Kling follow this submit-task-then-poll shape.
export interface VideoGenProvider {
  submitImageToVideo(input: SubmitImageToVideoInput): Promise<{ providerTaskId: string }>;
  pollTask(providerTaskId: string): Promise<VideoGenTaskResult>;
}
