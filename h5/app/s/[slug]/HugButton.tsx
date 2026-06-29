"use client";

import { useState, useEffect } from "react";

const API = process.env.NEXT_PUBLIC_API_URL;
const FINGERPRINT_KEY = "sf_visitor_id";
const huggedKey = (slug: string) => `sf_hug:${slug}`;

function getOrCreateFingerprint(): string {
  let fp = localStorage.getItem(FINGERPRINT_KEY);
  if (!fp) {
    fp = crypto.randomUUID();
    localStorage.setItem(FINGERPRINT_KEY, fp);
  }
  return fp;
}

type HugState = "idle" | "submitting" | "error";

export default function HugSection({
  slug,
  initialHugCount,
  hugEnabled,
}: {
  slug: string;
  initialHugCount: number;
  hugEnabled: boolean;
}) {
  const [hasHugged, setHasHugged] = useState(false);
  const [hugCount, setHugCount] = useState(initialHugCount);
  const [state, setState] = useState<HugState>("idle");

  useEffect(() => {
    if (localStorage.getItem(huggedKey(slug))) {
      setHasHugged(true);
    }
  }, [slug]);

  async function sendHug() {
    if (hasHugged || state === "submitting") return;
    setState("submitting");
    const fingerprint = getOrCreateFingerprint();
    try {
      const res = await fetch(`${API}/api/v1/shares/${slug}/hugs`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ visitorFingerprint: fingerprint }),
      });
      const data = (await res.json()) as { status: string };
      if (data.status === "success") {
        localStorage.setItem(huggedKey(slug), "true");
        setHasHugged(true);
        setHugCount((c) => c + 1);
        setState("idle");
      } else if (data.status === "already_hugged") {
        localStorage.setItem(huggedKey(slug), "true");
        setHasHugged(true);
        setState("idle");
      } else {
        setState("error");
      }
    } catch {
      setState("error");
    }
  }

  // ── Disabled ────────────────────────────────────────────────────────────────
  if (!hugEnabled) {
    return (
      <p
        className="text-center text-sm py-1"
        style={{ color: "rgba(138,128,120,0.70)", letterSpacing: "0.02em" }}
      >
        主人暂时没有开放抱抱
      </p>
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────
  if (state === "error") {
    return (
      <div className="flex flex-col items-center gap-3">
        <p className="text-sm text-center" style={{ color: "#8a8078" }}>
          暂时没有抱到TA，请再试一次
        </p>
        <button
          onClick={() => setState("idle")}
          className="text-sm underline"
          style={{ color: "#526744", minHeight: "44px" }}
        >
          重新试一次
        </button>
      </div>
    );
  }

  // ── Already hugged ──────────────────────────────────────────────────────────
  if (hasHugged) {
    return (
      <div className="flex flex-col items-center gap-2 py-1">
        <div
          className="flex items-center gap-2 px-5 py-3 rounded-full"
          style={{ background: "rgba(82,103,68,0.10)" }}
        >
          {/* heart filled */}
          <svg width="15" height="15" viewBox="0 0 15 15" fill="none" aria-hidden="true">
            <path
              d="M7.5 12.8S1.5 9 1.5 5.3a3.2 3.2 0 0 1 6-1.5 3.2 3.2 0 0 1 6 1.5c0 3.7-6 7.5-6 7.5z"
              fill="#526744"
            />
          </svg>
          <span
            className="text-sm font-medium"
            style={{ color: "#526744", letterSpacing: "0.03em" }}
          >
            已经轻轻抱抱过TA
          </span>
        </div>
        <p className="text-xs" style={{ color: "#a89e94" }}>
          你的心意已经留下了
        </p>
        {hugCount > 0 && (
          <p className="text-xs" style={{ color: "#b8b0a6" }}>
            已有 {hugCount} 个抱抱
          </p>
        )}
      </div>
    );
  }

  // ── Idle / submitting ────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col items-center gap-3">
      <p
        className="text-xs text-center"
        style={{ color: "#a89e94", letterSpacing: "0.04em" }}
      >
        让主人知道，你也记得TA
      </p>

      {/* Main hug button */}
      <button
        onClick={sendHug}
        disabled={state === "submitting"}
        className="w-full rounded-full text-white text-sm font-medium transition-opacity"
        style={{
          background:
            state === "submitting"
              ? "rgba(82,103,68,0.55)"
              : "linear-gradient(135deg,#6b8a54 0%,#526744 100%)",
          padding: "14px 24px",
          minHeight: "50px",
          letterSpacing: "0.05em",
          cursor: state === "submitting" ? "not-allowed" : "pointer",
          boxShadow:
            state === "submitting"
              ? "none"
              : "0 4px 16px rgba(82,103,68,0.28)",
        }}
        aria-label="轻轻抱抱TA"
      >
        {state === "submitting" ? (
          <span className="flex items-center justify-center gap-2">
            <span
              className="inline-block rounded-full border-2 border-white/40 border-t-white animate-spin"
              style={{ width: "14px", height: "14px" }}
            />
            正在送出抱抱……
          </span>
        ) : (
          "轻轻抱抱TA ♡"
        )}
      </button>

      {hugCount > 0 && (
        <p className="text-xs" style={{ color: "#b8b0a6", letterSpacing: "0.03em" }}>
          已有 {hugCount} 个抱抱
        </p>
      )}
    </div>
  );
}
