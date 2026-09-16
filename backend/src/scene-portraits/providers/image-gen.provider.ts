export const IMAGE_GEN_PROVIDER = 'IMAGE_GEN_PROVIDER';

export interface GeneratedImage {
  buffer: Buffer;
  contentType: string;
}

export interface GenerateCandidatesInput {
  referenceImageUrl: string;
  sceneText: string;
  count: number;
}

// Swappable behind SCENE_PORTRAIT_IMAGE_PROVIDER — see scene-portraits.module.ts.
export interface ImageGenProvider {
  generateCandidates(input: GenerateCandidatesInput): Promise<GeneratedImage[]>;
}
