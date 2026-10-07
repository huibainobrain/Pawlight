// Narrative Rules (PRD §4.1, §9/§48 of the dev task spec): the rules an
// EventTextGenProvider must obey when expressing facts as text. Structured
// as separate, independently-editable dimensions — not one opaque prompt
// string — so a human (or a future real provider's own prompt-construction
// code) can find and update exactly one dimension (e.g. add real few-shot
// examples) without touching the others or any generation-pipeline code.
//
// positiveExamples/negativeExamples are intentionally empty: these are
// human-curated content, not something to invent this round (per explicit
// instruction — Fake providers keep using their own hardcoded test strings,
// unaffected by this file). Filling them in later is a content change here,
// never a code change in PlanetEventGenerationService or any provider.

export interface NarrativeExample {
  language: 'zh' | 'en';
  facts: string; // short human description of the input facts this example answers
  text: string; // the example title+body a human considers "done right"
}

// PRD §4.1 / §48: what the provider must never do, regardless of language.
export const NARRATIVE_PROHIBITIONS: string[] = [
  '禁止第一人称：不能让 TA 自己说话，不能出现"我"。',
  '禁止人格模拟：不能描写 TA 对主人的想念、牵挂、情绪推测。',
  '禁止真实世界断言：不能暗示 TA 真实存在于另一个世界，或正在向主人传递讯息。',
  '禁止扩写：不能编造 facts 之外的新事实、新地点、新角色、新事件。',
];

// PRD §4.1: the voice the text should read in.
export const NARRATIVE_TONE_GUIDELINES: string[] = [
  '第三人称，温和、克制，像旁观者记录下的一个瞬间，而不是宣告或总结。',
  '只描述当下这一个小片段，不展望未来，不回顾过去。',
];

// PRD §48: roughly how long the body should run.
export const NARRATIVE_LENGTH_GUIDANCE =
  '正文约 30-60 字（中文）或等长的简短英文。';

// Filled in by a human once a real text provider exists — see file header.
export const NARRATIVE_POSITIVE_EXAMPLES: NarrativeExample[] = [];
export const NARRATIVE_NEGATIVE_EXAMPLES: NarrativeExample[] = [];

// Flattened, prompt-ready form for a provider that just wants one string —
// this is what EventTextGenProvider.generate() actually receives today via
// GenerateEventTextInput.narrativeRules. Kept as the stable public shape so
// adding to any dimension above never changes the provider interface.
export const NARRATIVE_RULES = [
  ...NARRATIVE_PROHIBITIONS,
  ...NARRATIVE_TONE_GUIDELINES,
  NARRATIVE_LENGTH_GUIDANCE,
].join(' ');

// Placeholder until a real stable-identity asset pipeline exists (PRD §42).
// A real EventImageGenProvider will eventually read this from a per-pet
// "stable generation profile" built from the pet's own reference photos —
// not invented here. (The equivalent placeholder for world/style visuals,
// formerly WORLD_VISUAL_PLACEHOLDER here, is retired — Planet Style is now a
// real, versioned PlanetStyle DB row; see PlanetEventGenerationService,
// which reads homeProfile.planetStyle.imageGenGuidance instead.)
export const STABLE_IDENTITY_PLACEHOLDER =
  'Maintain the same pet identity as the reference photo across all generated images.';
