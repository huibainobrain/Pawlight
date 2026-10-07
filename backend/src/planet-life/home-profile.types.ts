// Shape of HomeProfile.visualSnapshot (stored as Prisma Json — this is the
// TS-side contract for it, read by providers and written once by
// HomeProfileService at initialization, never recomputed afterward).

export interface HomeVisualVariant {
  key: string;
  nameZh: string;
  nameEn: string;
  imageGenPrompt: string;
}

export interface HomeVisualSnapshot {
  cottageBlueprint: HomeVisualVariant;
  palette: HomeVisualVariant & { colorTokens: string[] | null };
  roof: HomeVisualVariant;
  door: HomeVisualVariant;
  window: HomeVisualVariant;
  signaturePlant: HomeVisualVariant;
  nameplateText: string;
  // Mechanical concatenation of the fields above, built once at init — a
  // convenience for a provider that wants one descriptive paragraph instead
  // of assembling the individual fields itself. Never AI-generated.
  summaryPrompt: string;
}
