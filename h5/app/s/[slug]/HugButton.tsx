"use client";

import { useState } from "react";

const API = process.env.NEXT_PUBLIC_API_URL;

export default function HugButton({ slug }: { slug: string }) {
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  async function sendHug() {
    setLoading(true);
    try {
      await fetch(`${API}/api/v1/shares/${slug}/hugs`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      setSent(true);
    } finally {
      setLoading(false);
    }
  }

  if (sent) {
    return (
      <div className="text-center py-4">
        <p className="text-2xl mb-1">🤍</p>
        <p className="text-sm text-muted">抱抱已送出</p>
      </div>
    );
  }

  return (
    <button
      onClick={sendHug}
      disabled={loading}
      className="w-full py-4 rounded-xl text-white text-base font-medium disabled:opacity-60"
      style={{ backgroundColor: "#526744" }}
    >
      {loading ? "送出中..." : "送出一个抱抱 🤍"}
    </button>
  );
}
