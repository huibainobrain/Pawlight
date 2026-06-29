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

// Small heart icon used throughout
function HeartIcon({ filled = false }: { filled?: boolean }) {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      {filled ? (
        <path
          d="M8 13.5S2 9.8 2 5.8A3.3 3.3 0 0 1 8 4a3.3 3.3 0 0 1 6 2c0 4-6 7.5-6 7.5z"
          fill="#c97b7b"
        />
      ) : (
        <path
          d="M8 13.5S2 9.8 2 5.8A3.3 3.3 0 0 1 8 4a3.3 3.3 0 0 1 6 2c0 4-6 7.5-6 7.5z"
          stroke="#c97b7b"
          strokeWidth="1.2"
          fill="none"
        />
      )}
    </svg>
  );
}

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

  if (!hugEnabled) {
    return (
      <p className="text-center text-sm py-3" style={{ color: "#8a8078" }}>
        主人暂时没有开放抱抱
      </p>
    );
  }

  if (state === "error") {
    return (
      <div className="text-center py-2">
        <p className="text-sm mb-3" style={{ color: "#8a8078" }}>
          抱抱暂时没有送出，请稍后再试。
        </p>
        <button
          onClick={() => setState("idle")}
          className="text-sm underline"
          style={{ color: "#526744" }}
        >
          重新试一次
        </button>
      </div>
    );
  }

  if (hasHugged) {
    return (
      <div className="flex flex-col items-center gap-3 py-2">
        <div className="flex items-center gap-2">
          <HeartIcon filled />
          <span className="text-base font-medium" style={{ color: "#526744", fontFamily: "Georgia, serif" }}>
            已抱抱
          </span>
        </div>
        <p className="text-sm text-center" style={{ color: "#8a8078" }}>
          你的心意已经留在这里了。
        </p>
        {hugCount > 0 && (
          <p className="text-xs" style={{ color: "#a89e94" }}>
            已有 {hugCount} 位朋友轻轻抱过TA
          </p>
        )}
      </div>
    );
  }

  // Default: can hug
  return (
    <div className="flex flex-col items-center gap-4 py-1">
      <div className="flex items-center gap-1.5">
        <HeartIcon />
        <span className="text-sm font-medium" style={{ color: "#526744" }}>
          抱抱记录
        </span>
      </div>

      {hugCount > 0 && (
        <p className="text-sm" style={{ color: "#8a8078" }}>
          已有{" "}
          <span style={{ color: "#526744", fontWeight: 500 }}>{hugCount}</span>{" "}
          位朋友轻轻抱过TA
        </p>
      )}

      <p className="text-xs text-center leading-relaxed" style={{ color: "#a89e94" }}>
        让主人知道，你也记得TA
      </p>

      <button
        onClick={sendHug}
        disabled={state === "submitting"}
        className="w-full py-3.5 rounded-2xl text-white text-sm font-medium transition-opacity"
        style={{
          background: "linear-gradient(135deg, #6b8a54 0%, #526744 100%)",
          opacity: state === "submitting" ? 0.55 : 1,
          cursor: state === "submitting" ? "not-allowed" : "pointer",
          letterSpacing: "0.04em",
          boxShadow: "0 2px 12px rgba(82,103,68,0.20)",
        }}
      >
        {state === "submitting" ? "正在留下抱抱……" : "轻轻抱抱TA ♡"}
      </button>
    </div>
  );
}
