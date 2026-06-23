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

  // Read localStorage after mount — cannot access on server
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
        // Sync client state with server truth
        localStorage.setItem(huggedKey(slug), "true");
        setHasHugged(true);
        setState("idle");
      } else {
        // hug_disabled, not_found, private_or_unavailable — treat as non-retriable
        setState("error");
      }
    } catch {
      setState("error");
    }
  }

  // Hug disabled by owner
  if (!hugEnabled) {
    return (
      <p className="text-center text-sm py-2" style={{ color: "#8a8078" }}>
        主人暂时没有开放抱抱
      </p>
    );
  }

  // Already hugged (from localStorage or after successful POST)
  if (hasHugged) {
    return (
      <div className="text-center py-1">
        <p className="text-base font-medium mb-1" style={{ color: "#526744" }}>
          已抱抱
        </p>
        <p className="text-sm" style={{ color: "#8a8078" }}>
          你的心意已经留下了。
        </p>
        {hugCount > 0 && (
          <p className="text-xs mt-3" style={{ color: "#8a8078" }}>
            已经有 {hugCount} 位朋友轻轻抱过TA
          </p>
        )}
      </div>
    );
  }

  // Network / server error — keep page, offer retry
  if (state === "error") {
    return (
      <div className="text-center py-1">
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

  // Default: can hug
  return (
    <div>
      <p className="text-center text-sm mb-4" style={{ color: "#8a8078" }}>
        让主人知道，你也记得TA。
      </p>
      <button
        onClick={sendHug}
        disabled={state === "submitting"}
        className="w-full py-4 rounded-xl text-white text-base font-medium transition-opacity"
        style={{
          backgroundColor: "#526744",
          opacity: state === "submitting" ? 0.6 : 1,
          cursor: state === "submitting" ? "not-allowed" : "pointer",
        }}
      >
        {state === "submitting" ? "正在留下抱抱……" : "轻轻抱抱TA"}
      </button>
      {hugCount > 0 && (
        <p className="text-center text-xs mt-3" style={{ color: "#8a8078" }}>
          已经有 {hugCount} 位朋友轻轻抱过TA
        </p>
      )}
    </div>
  );
}
