import Image from "next/image";
import HugSection from "./HugButton";
import PhotoGrid from "./PhotoGrid";
import ShareButton from "./ShareButton";

const API = process.env.NEXT_PUBLIC_API_URL;

// ── Types ────────────────────────────────────────────────────────────────────

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

// ── Data fetching ────────────────────────────────────────────────────────────

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

// ── Metadata ─────────────────────────────────────────────────────────────────

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
    openGraph: {
      title: `${data.petName}的纪念`,
      description:
        data.memorialSentence ?? `来看看${data.petName}留在星屿的纪念`,
      images: data.mainPhoto ? [{ url: data.mainPhoto }] : [],
    },
  };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function formatDateShort(s?: string | null): string | null {
  if (!s) return null;
  const d = new Date(s);
  if (isNaN(d.getTime())) return null;
  return `${d.getFullYear()}年${d.getMonth() + 1}月`;
}

// ── State pages ──────────────────────────────────────────────────────────────

function StatePage({ children }: { children: React.ReactNode }) {
  return (
    <main
      className="flex flex-col items-center justify-center min-h-screen px-8 text-center"
      style={{ background: "#f7f1e8" }}
    >
      {children}
    </main>
  );
}

function PrivatePage() {
  return (
    <StatePage>
      <div
        className="mb-6 opacity-20"
        style={{ fontSize: "40px", lineHeight: 1 }}
      >
        🌙
      </div>
      <h1
        className="text-xl font-medium mb-3"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        这颗星球暂时只给主人自己可见
      </h1>
      <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
        也许主人还想把这份回忆先安静地留在身边。
      </p>
    </StatePage>
  );
}

function NotFoundPage() {
  return (
    <StatePage>
      <div
        className="mb-6 opacity-20"
        style={{ fontSize: "40px", lineHeight: 1 }}
      >
        🌙
      </div>
      <h1
        className="text-xl font-medium mb-3"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        这段纪念暂时无法查看
      </h1>
      <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
        也许链接已经失效，或主人已经调整了纪念页。
      </p>
    </StatePage>
  );
}

function ErrorPage() {
  return (
    <StatePage>
      <div
        className="mb-6 opacity-20"
        style={{ fontSize: "40px", lineHeight: 1 }}
      >
        🌙
      </div>
      <h1
        className="text-xl font-medium mb-3"
        style={{ color: "#2c2c2c", fontFamily: "Georgia, serif" }}
      >
        页面暂时没有加载出来
      </h1>
      <p className="text-sm mb-5" style={{ color: "#8a8078" }}>
        可以稍后再试一次。
      </p>
      <a href="." className="text-sm underline" style={{ color: "#526744" }}>
        重新加载
      </a>
    </StatePage>
  );
}

// ── Section label ─────────────────────────────────────────────────────────────

function SectionLabel({
  icon,
  children,
}: {
  icon: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-center gap-2 mb-4">
      {icon}
      <span
        className="text-sm font-medium tracking-wide"
        style={{ color: "#526744" }}
      >
        {children}
      </span>
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────

const IconLeaf = () => (
  <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
    <path
      d="M2 12c1-4 4-8 10-9.5C10.5 6 8 9 2 12z"
      stroke="#7e9366"
      strokeWidth="1.2"
      fill="none"
      strokeLinejoin="round"
    />
    <path d="M2 12l4-4" stroke="#7e9366" strokeWidth="1.1" strokeLinecap="round" />
  </svg>
);

const IconPhoto = () => (
  <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
    <rect x="1.5" y="2.5" width="11" height="9" rx="2" stroke="#7e9366" strokeWidth="1.2" />
    <circle cx="5" cy="6" r="1.3" stroke="#7e9366" strokeWidth="1.1" />
    <path d="M1.5 9.5L5 7l2.5 2.5L9.5 7 12.5 11.5" stroke="#7e9366" strokeWidth="1.1" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

// ── Main page ─────────────────────────────────────────────────────────────────

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
        ? `${leftStr} 离开`
        : arrivedStr
          ? `${arrivedStr} 来到`
          : null;

  const shareTitle = `${data.petName}的纪念`;
  const shareText =
    data.memorialSentence ?? `来看看${data.petName}留在星屿的纪念`;

  return (
    <main
      className="max-w-md mx-auto"
      style={{ background: "#f7f1e8", minHeight: "100vh" }}
    >

      {/* ══════════════════════════════════════════════════════════════
          HERO — atmospheric full-width section
          Layer 1: bg-page image (botanical atmosphere)
          Layer 2: ring decoration around pet photo
          Layer 3: name + sentence
      ══════════════════════════════════════════════════════════════ */}
      <section className="relative overflow-visible" style={{ minHeight: "420px" }}>

        {/* Background botanical image — fills hero, flowers at base */}
        <div className="absolute inset-0 overflow-hidden" style={{ zIndex: 0 }}>
          <Image
            src="/h5-bg-page.jpg"
            alt=""
            fill
            className="object-cover object-top"
            priority
            sizes="448px"
          />
          {/* Gradient fade to page bg color at the bottom */}
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom, rgba(247,241,232,0.10) 0%, rgba(247,241,232,0.30) 55%, rgba(247,241,232,0.95) 85%, #f7f1e8 100%)",
            }}
          />
        </div>

        {/* Pet photo + botanical ring */}
        <div
          className="relative flex flex-col items-center"
          style={{ paddingTop: "52px", zIndex: 1 }}
        >
          {/* Ring frame container — sized to match h5-hero-ring.png aspect ratio */}
          <div className="relative" style={{ width: "280px", height: "210px" }}>
            {/* Botanical ring decoration image */}
            <Image
              src="/h5-hero-ring.png"
              alt=""
              fill
              className="object-contain"
              priority
              sizes="280px"
            />
            {/* Pet photo — circular, centered inside the ring
                Adjust top/left/width/height to align with the ring circle area */}
            <div
              className="absolute rounded-full overflow-hidden"
              style={{
                top: "6px",
                left: "50%",
                transform: "translateX(-50%)",
                width: "152px",
                height: "152px",
                zIndex: 1,
                boxShadow: "0 4px 20px rgba(0,0,0,0.10)",
              }}
            >
              {data.mainPhoto ? (
                <Image
                  src={data.mainPhoto}
                  alt={data.petName}
                  fill
                  className="object-cover"
                  priority
                  sizes="152px"
                />
              ) : (
                <div
                  className="w-full h-full flex items-center justify-center"
                  style={{ background: "#e8e0d4" }}
                >
                  <span style={{ fontSize: "36px" }}>🐾</span>
                </div>
              )}
            </div>
          </div>

          {/* Name + dates + sentence */}
          <div
            className="text-center px-6"
            style={{ marginTop: "18px", paddingBottom: "32px" }}
          >
            <h1
              className="font-bold tracking-wide"
              style={{
                fontFamily: "Georgia, 'Noto Serif SC', serif",
                color: "#2c2c2c",
                fontSize: "30px",
                lineHeight: 1.2,
              }}
            >
              {data.petName}
            </h1>

            {datesLine && (
              <p
                className="text-xs mt-2"
                style={{ color: "#a89e94", letterSpacing: "0.04em" }}
              >
                {datesLine}
              </p>
            )}

            {data.memorialSentence && (
              <div className="mt-4">
                <p
                  className="text-sm leading-relaxed"
                  style={{
                    color: "#6e6258",
                    fontFamily: "Georgia, serif",
                    fontStyle: "italic",
                    lineHeight: "1.8",
                  }}
                >
                  {data.memorialSentence}
                </p>
                <p
                  className="text-xs mt-2 opacity-45"
                  style={{ color: "#8a8078", letterSpacing: "0.06em" }}
                >
                  ✦ 来自主人的一句纪念
                </p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════════════
          CONTENT CARDS — each card is independent, length-adaptive
      ══════════════════════════════════════════════════════════════ */}
      <div className="px-4 space-y-4" style={{ paddingBottom: "0" }}>

        {/* ── Story card ─────────────────────────────────────── */}
        {data.story && (
          <div className="relative rounded-2xl overflow-hidden">
            {/* Card background: botanical portrait card */}
            <div className="absolute inset-0" style={{ zIndex: 0 }}>
              <Image
                src="/h5-card-story.jpg"
                alt=""
                fill
                className="object-cover object-center"
                sizes="(max-width: 448px) calc(100vw - 32px), 416px"
              />
              {/* Semi-transparent overlay so text is always readable */}
              <div
                className="absolute inset-0"
                style={{ background: "rgba(252,249,244,0.88)" }}
              />
            </div>

            {/* Card content */}
            <div className="relative px-5 py-5" style={{ zIndex: 1 }}>
              <SectionLabel icon={<IconLeaf />}>TA的故事</SectionLabel>
              <p
                className="text-sm leading-relaxed whitespace-pre-wrap"
                style={{
                  color: "#3a3530",
                  lineHeight: "1.9",
                  fontFamily: "'PingFang SC', 'Hiragino Sans GB', sans-serif",
                }}
              >
                {data.story}
              </p>
            </div>
          </div>
        )}

        {/* ── Photo memories ──────────────────────────────────── */}
        {data.albumPhotos.length > 0 && (
          <div
            className="rounded-2xl overflow-hidden py-5"
            style={{
              background: "rgba(255,255,255,0.68)",
              border: "1px solid rgba(232,224,212,0.8)",
            }}
          >
            <div className="px-5">
              <SectionLabel icon={<IconPhoto />}>照片回忆</SectionLabel>
            </div>
            {/* 2-column photo grid — PhotoGrid handles lightbox */}
            <PhotoGrid photos={data.albumPhotos} />
          </div>
        )}

        {/* ── Hug section ─────────────────────────────────────── */}
        <div className="relative rounded-2xl overflow-hidden">
          {/* Card background: botanical wide card */}
          <div className="absolute inset-0" style={{ zIndex: 0 }}>
            <Image
              src="/h5-card-wide.jpg"
              alt=""
              fill
              className="object-cover object-center"
              sizes="(max-width: 448px) calc(100vw - 32px), 416px"
            />
            <div
              className="absolute inset-0"
              style={{ background: "rgba(252,249,244,0.86)" }}
            />
          </div>
          <div className="relative px-5 py-5" style={{ zIndex: 1 }}>
            <HugSection
              slug={slug}
              initialHugCount={data.hugCount}
              hugEnabled={data.hugEnabled}
            />
          </div>
        </div>
      </div>

      {/* ══════════════════════════════════════════════════════════════
          FOOTER — botanical closing section
      ══════════════════════════════════════════════════════════════ */}
      <footer className="relative mt-6 overflow-hidden" style={{ minHeight: "280px" }}>
        {/* Background: botanical wide card image rotated for footer feel */}
        <div className="absolute inset-0" style={{ zIndex: 0 }}>
          <Image
            src="/h5-card-wide.jpg"
            alt=""
            fill
            className="object-cover object-bottom"
            sizes="448px"
          />
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom, #f7f1e8 0%, rgba(247,241,232,0.72) 25%, rgba(247,241,232,0.62) 60%, rgba(247,241,232,0.88) 100%)",
            }}
          />
        </div>

        {/* Footer content */}
        <div
          className="relative flex flex-col items-center text-center px-8 py-10"
          style={{ zIndex: 1 }}
        >
          <h2
            className="text-xl font-medium"
            style={{
              fontFamily: "Georgia, 'Noto Serif SC', serif",
              color: "#2c2c2c",
              letterSpacing: "0.04em",
            }}
          >
            谢谢你来看TA
          </h2>
          <p
            className="text-sm mt-2 leading-relaxed"
            style={{ color: "#8a8078", lineHeight: "1.8" }}
          >
            TA在这里被爱着，
            <br />
            因为你而被记得。
          </p>

          <div className="mt-5">
            <ShareButton title={shareTitle} text={shareText} />
          </div>

          {/* Divider */}
          <div
            className="mt-7 mb-4"
            style={{
              width: "32px",
              height: "1px",
              background: "rgba(138,128,120,0.25)",
            }}
          />

          <p
            className="text-xs"
            style={{ color: "#a89e94", letterSpacing: "0.06em" }}
          >
            ❧ 这份想念，会一直留在这里 ❧
          </p>

          <p
            className="text-xs mt-8 opacity-30"
            style={{ color: "#8a8078", letterSpacing: "0.04em" }}
          >
            由星屿纪念生成
          </p>
        </div>
      </footer>
    </main>
  );
}
