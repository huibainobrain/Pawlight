import Image from "next/image";
import HugSection from "./HugButton";

const API = process.env.NEXT_PUBLIC_API_URL;

// ---- Types ----------------------------------------------------------------

interface AlbumPhoto {
  id: string;
  url: string;
  caption?: string | null;
}

interface ShareData {
  status: "ok";
  slug: string;
  hugEnabled: boolean;
  petName: string;
  petType: string;
  mainPhoto: string | null;
  memorialSentence?: string | null;
  story?: string | null;
  arrivedOn?: string | null;
  bornOn?: string | null;
  leftOn?: string | null;
  albumPhotos: AlbumPhoto[];
  hugCount: number;
  viewerHasHugged: boolean;
}

type FetchResult =
  | { type: "ok"; data: ShareData }
  | { type: "private" }
  | { type: "not_found" }
  | { type: "error" };

// ---- Data fetching ---------------------------------------------------------

async function fetchShare(slug: string): Promise<FetchResult> {
  try {
    const res = await fetch(`${API}/api/v1/shares/${slug}`, {
      next: { revalidate: 60 },
    });
    if (res.status === 403) return { type: "private" };
    if (res.status === 404) return { type: "not_found" };
    if (!res.ok) return { type: "error" };
    const data = await res.json();
    return { type: "ok", data };
  } catch {
    return { type: "error" };
  }
}

// ---- Metadata --------------------------------------------------------------

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const result = await fetchShare(slug);
  if (result.type !== "ok") return { title: "星屿纪念" };
  const { data } = result;
  return {
    title: `${data.petName}的纪念 · 星屿纪念`,
    description:
      data.memorialSentence ?? `来看看${data.petName}留在星屿的纪念`,
  };
}

// ---- Helpers ---------------------------------------------------------------

function formatDateShort(s?: string | null): string | null {
  if (!s) return null;
  const d = new Date(s);
  if (isNaN(d.getTime())) return null;
  return `${d.getFullYear()}年${d.getMonth() + 1}月`;
}

// ---- State pages -----------------------------------------------------------

function PrivatePage() {
  return (
    <main className="flex flex-col items-center justify-center min-h-screen px-8 text-center">
      <svg
        className="mb-6 opacity-25"
        width="52"
        height="52"
        viewBox="0 0 52 52"
        fill="none"
      >
        <circle cx="26" cy="26" r="26" fill="#8a8078" />
        <rect x="16" y="24" width="20" height="14" rx="3" fill="white" />
        <path
          d="M20 24v-5a6 6 0 0 1 12 0v5"
          stroke="white"
          strokeWidth="2"
          strokeLinecap="round"
          fill="none"
        />
      </svg>
      <h1
        className="text-xl font-medium mb-4"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        这颗星球暂时只给主人自己可见
      </h1>
      <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
        也许主人还想把这份回忆先安静地留在身边。
      </p>
    </main>
  );
}

function NotFoundPage() {
  return (
    <main className="flex flex-col items-center justify-center min-h-screen px-8 text-center">
      <p className="text-5xl mb-6 opacity-20">🌙</p>
      <h1
        className="text-xl font-medium mb-4"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        这段纪念暂时无法查看
      </h1>
      <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
        也许链接已经失效，或主人已经调整了纪念页。
      </p>
    </main>
  );
}

function ErrorPage() {
  return (
    <main className="flex flex-col items-center justify-center min-h-screen px-8 text-center">
      <p className="text-5xl mb-6 opacity-20">🌙</p>
      <h1
        className="text-xl font-medium mb-3"
        style={{ color: "#2c2c2c" }}
      >
        页面暂时没有加载出来
      </h1>
      <p className="text-sm mb-5" style={{ color: "#8a8078" }}>
        可以稍后再试一次。
      </p>
      {/* href="." navigates to current route without hash — reloads the page */}
      <a
        href="."
        className="text-sm underline"
        style={{ color: "#526744" }}
      >
        重新加载
      </a>
    </main>
  );
}

// ---- Main page -------------------------------------------------------------

export default async function SharePage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const result = await fetchShare(slug);

  if (result.type === "private") return <PrivatePage />;
  if (result.type === "not_found") return <NotFoundPage />;
  if (result.type === "error") return <ErrorPage />;

  const { data } = result;

  const arrivedStr = formatDateShort(data.arrivedOn);
  const leftStr = formatDateShort(data.leftOn);
  const datesLine =
    arrivedStr && leftStr
      ? `${arrivedStr} — ${leftStr}`
      : leftStr
        ? `${leftStr}离开`
        : arrivedStr
          ? `${arrivedStr}来到`
          : null;

  return (
    <main className="max-w-md mx-auto pb-16">
      {/* ── Main photo ─────────────────────────────────────────────────── */}
      <div className="relative w-full aspect-[4/3]">
        {data.mainPhoto ? (
          <Image
            src={data.mainPhoto}
            alt={data.petName}
            fill
            className="object-cover"
            priority
          />
        ) : (
          <div
            className="w-full h-full flex items-center justify-center"
            style={{ background: "#e8e0d4" }}
          >
            <p className="text-sm" style={{ color: "#8a8078" }}>
              TA的照片暂时没有加载出来
            </p>
          </div>
        )}
      </div>

      {/* ── Name / dates / memorial sentence ───────────────────────────── */}
      <div className="px-5 pt-6 pb-2 text-center">
        <h1
          className="text-2xl font-semibold"
          style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
        >
          {data.petName}
        </h1>
        {datesLine && (
          <p className="text-xs mt-1" style={{ color: "#8a8078" }}>
            {datesLine}
          </p>
        )}
        {data.memorialSentence && (
          <p
            className="text-sm leading-relaxed mt-3"
            style={{ color: "#8a8078" }}
          >
            {data.memorialSentence}
          </p>
        )}
      </div>

      {/* ── Content cards ──────────────────────────────────────────────── */}
      <div className="px-5 mt-4 space-y-4">
        {/* Story — only shown if exists */}
        {data.story && (
          <div
            className="rounded-2xl p-5"
            style={{ background: "#fff", border: "1px solid #e8e0d4" }}
          >
            <p
              className="text-xs font-medium mb-3"
              style={{ color: "#7e9366" }}
            >
              TA的故事
            </p>
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "#2c2c2c" }}
            >
              {data.story}
            </p>
          </div>
        )}

        {/* Album photos — only shown if exists */}
        {data.albumPhotos.length > 0 && (
          <div
            className="rounded-2xl overflow-hidden"
            style={{ background: "#fff", border: "1px solid #e8e0d4" }}
          >
            <p
              className="text-xs font-medium px-5 pt-4 pb-3"
              style={{ color: "#7e9366" }}
            >
              照片回忆
            </p>
            <div className="grid grid-cols-3 gap-px bg-line">
              {data.albumPhotos.map((photo) => (
                <div key={photo.id} className="relative aspect-square bg-paper">
                  <Image
                    src={photo.url}
                    alt={photo.caption ?? ""}
                    fill
                    className="object-cover"
                  />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Hug section — always shown */}
        <div
          className="rounded-2xl p-5"
          style={{ background: "#fff", border: "1px solid #e8e0d4" }}
        >
          <HugSection
            slug={slug}
            initialHugCount={data.hugCount}
            hugEnabled={data.hugEnabled}
          />
        </div>

        {/* Weak app guide — bottom, understated */}
        <div className="text-center pt-2 pb-1">
          <p className="text-xs" style={{ color: "#8a8078" }}>
            也想为重要的TA留下一处安静的纪念？
          </p>
          <p className="text-xs mt-4 opacity-40" style={{ color: "#8a8078" }}>
            由星屿纪念生成
          </p>
        </div>
      </div>
    </main>
  );
}
