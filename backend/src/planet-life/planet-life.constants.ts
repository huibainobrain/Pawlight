// Adjustable defaults, not locked-in product decisions.
export const MIN_EVENT_INTERVAL_HOURS = 48;
export const MAX_EVENT_INTERVAL_HOURS = 96;
export const WEEKLY_EVENT_CAP = 3;
export const WEEKLY_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
// How often the scheduler tick runs — not how often an event is generated.
// Frequent enough that the 48-96h window feels organic, cheap enough to run
// forever with no queue/worker infra.
export const SCHEDULER_TICK_CRON = '*/15 * * * *'; // every 15 minutes
export const GENERATION_MAX_RETRIES = 1; // PRD §49: "自动重试" once, then silently wait for the next tick
