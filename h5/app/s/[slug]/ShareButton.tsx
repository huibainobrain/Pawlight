"use client";

import { useState } from "react";

export default function ShareButton({ title, text }: { title: string; text: string }) {
  const [copied, setCopied] = useState(false);

  async function handleShare() {
    const url = window.location.href;
    if (navigator.share) {
      try {
        await navigator.share({ title, text, url });
      } catch {
        // user cancelled — no-op
      }
      return;
    }
    // Fallback: copy link
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2200);
    } catch {
      // clipboard not available — silent fail
    }
  }

  return (
    <button
      onClick={handleShare}
      className="flex items-center gap-2 px-6 py-3 rounded-full text-sm transition-opacity active:opacity-70"
      style={{
        border: "1px solid rgba(82,103,68,0.35)",
        color: "#526744",
        background: "rgba(255,255,255,0.72)",
        fontWeight: 500,
        letterSpacing: "0.02em",
      }}
    >
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
        <circle cx="11" cy="2.5" r="1.8" stroke="#526744" strokeWidth="1.2" fill="none" />
        <circle cx="11" cy="11.5" r="1.8" stroke="#526744" strokeWidth="1.2" fill="none" />
        <circle cx="3" cy="7" r="1.8" stroke="#526744" strokeWidth="1.2" fill="none" />
        <path d="M4.6 6.1L9.5 3.3M4.6 7.9l4.9 2.8" stroke="#526744" strokeWidth="1.2" strokeLinecap="round" />
      </svg>
      {copied ? "链接已复制" : "分享给也记得TA的人"}
    </button>
  );
}
