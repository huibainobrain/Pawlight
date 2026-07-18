import Image from "next/image";
import HugSection from "./HugButton";
import PhotoSection from "./PhotoGrid";
import ShareButton from "./ShareButton";
import { API_URL } from "@/lib/config";

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

type Lang = "en" | "zh";

// ── Data fetch ───────────────────────────────────────────────────────────────

async function fetchShare(slug: string): Promise<FetchResult> {
  try {
    const res = await fetch(`${API_URL}/api/v1/shares/${slug}`, {
      next: { revalidate: 60 },
    });
    if (res.status === 403) return { type: "private" };
    if (res.status === 404) return { type: "not_found" };
    if (!res.ok) return { type: "error" };
    return { type: "ok", data: await res.json() };
  } catch {
    return { type: "error" };
  }
}

// ── Bilingual helper ─────────────────────────────────────────────────────────

function t(lang: Lang, zh: string, en: string) { return lang === "zh" ? zh : en; }

// ── Metadata ─────────────────────────────────────────────────────────────────

export async function generateMetadata({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string }>;
}) {
  const { slug } = await params;
  const { lang: rawLang } = await searchParams;
  const lang: Lang = rawLang === "zh" ? "zh" : "en";
  const result = await fetchShare(slug);
  if (result.type !== "ok") return { title: lang === "zh" ? "留光" : "Pawlight" };
  const { data } = result;
  const title = lang === "zh"
    ? `${data.petName}的纪念 · 留光`
    : `${data.petName}'s keepsake · Pawlight`;
  const description = data.memorialSentence ?? (lang === "zh"
    ? `来看看${data.petName}留在留光的纪念`
    : `A gentle memorial for ${data.petName} on Pawlight`);
  return {
    title,
    description,
    openGraph: {
      title: lang === "zh" ? `${data.petName}的纪念` : `${data.petName}'s keepsake`,
      description,
      images: data.mainPhoto ? [{ url: data.mainPhoto }] : [],
    },
  };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function formatDateShort(s?: string | null, lang: Lang = "en"): string | null {
  if (!s) return null;
  const d = new Date(s);
  if (isNaN(d.getTime())) return null;
  if (lang === "zh") return `${d.getFullYear()}年${d.getMonth() + 1}月`;
  const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${months[d.getMonth()]} ${d.getFullYear()}`;
}

// ── State pages (warm, full-bleed) ────────────────────────────────────────────

function AtmosphereBg() {
  return (
    <div className="absolute inset-0 overflow-hidden">
      <Image
        src="/h5-bg-page.jpg"
        alt=""
        fill
        className="object-cover object-center"
        sizes="100vw"
        priority
      />
      <div
        className="absolute inset-0"
        style={{ background: "rgba(247,241,232,0.82)" }}
      />
    </div>
  );
}

function PrivatePage({ lang }: { lang: Lang }) {
  return (
    <div className="h5-hero relative w-full flex flex-col items-center justify-center text-center px-8">
      <AtmosphereBg />
      <div className="relative">
        <p className="text-4xl mb-6" style={{ opacity: 0.22 }}>
          🌙
        </p>
        <h1
          className="text-xl font-medium mb-3"
          style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
        >
          {t(lang, "这颗星球暂时只给主人自己可见", "This memorial is private for now")}
        </h1>
        <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
          {t(lang,
            "也许主人还想把这份回忆先安静地留在身边。",
            "The owner is keeping these memories close for a while."
          )}
        </p>
      </div>
    </div>
  );
}

function NotFoundPage({ lang }: { lang: Lang }) {
  return (
    <div className="h5-hero relative w-full flex flex-col items-center justify-center text-center px-8">
      <AtmosphereBg />
      <div className="relative">
        <p className="text-4xl mb-6" style={{ opacity: 0.22 }}>
          🌙
        </p>
        <h1
          className="text-xl font-medium mb-3"
          style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
        >
          {t(lang, "这段纪念暂时无法查看", "This memorial isn't available")}
        </h1>
        <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
          {t(lang,
            "也许链接已经失效，或主人已经调整了纪念页。",
            "The link may have expired, or the owner has made some changes."
          )}
        </p>
      </div>
    </div>
  );
}

function ErrorPage({ lang }: { lang: Lang }) {
  return (
    <div className="h5-hero relative w-full flex flex-col items-center justify-center text-center px-8">
      <AtmosphereBg />
      <div className="relative">
        <p className="text-4xl mb-6" style={{ opacity: 0.22 }}>
          🌙
        </p>
        <h1
          className="text-xl font-medium mb-3"
          style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
        >
          {t(lang, "页面暂时没有加载出来", "Couldn't load the page")}
        </h1>
        <p className="text-sm mb-5" style={{ color: "#8a8078" }}>
          {t(lang, "可以稍后再试一次。", "Please try again in a moment.")}
        </p>
        <a
          href="."
          className="text-sm underline"
          style={{ color: "#526744", minHeight: "44px", display: "inline-flex", alignItems: "center" }}
        >
          {t(lang, "重新加载", "Reload")}
        </a>
      </div>
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────

const IconLeaf = () => (
  <svg width="13" height="13" viewBox="0 0 13 13" fill="none" aria-hidden="true">
    <path
      d="M1.5 11.5c1-3.8 3.8-7.5 9.5-9C9.5 6 7 9 1.5 11.5z"
      stroke="#7e9366"
      strokeWidth="1.2"
      fill="none"
      strokeLinejoin="round"
    />
    <path d="M1.5 11.5l3.5-3.5" stroke="#7e9366" strokeWidth="1.1" strokeLinecap="round" />
  </svg>
);

const IconPhoto = () => (
  <svg width="13" height="13" viewBox="0 0 13 13" fill="none" aria-hidden="true">
    <rect x="1" y="2" width="11" height="9" rx="2" stroke="#7e9366" strokeWidth="1.2" />
    <circle cx="4.5" cy="5.5" r="1.2" stroke="#7e9366" strokeWidth="1.1" />
    <path
      d="M1 8.5L4 6.5 6.5 9 8.5 6.5 12 10"
      stroke="#7e9366"
      strokeWidth="1.1"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

// ── Main page ─────────────────────────────────────────────────────────────────

export default async function SharePage({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string }>;
}) {
  const { slug } = await params;
  const { lang: rawLang } = await searchParams;
  const lang: Lang = rawLang === "zh" ? "zh" : "en";
  const result = await fetchShare(slug);

  if (result.type === "private") return <PrivatePage lang={lang} />;
  if (result.type === "not_found") return <NotFoundPage lang={lang} />;
  if (result.type === "error") return <ErrorPage lang={lang} />;

  const { data } = result;

  const arrivedStr = formatDateShort(data.arrivedOn, lang);
  const leftStr = formatDateShort(data.leftOn, lang);
  const datesLine =
    arrivedStr && leftStr
      ? `${arrivedStr} — ${leftStr}`
      : leftStr
        ? lang === "zh" ? `${leftStr} 离开` : `left on ${leftStr}`
        : arrivedStr
          ? lang === "zh" ? `${arrivedStr} 来到` : `came home on ${arrivedStr}`
          : null;

  const hasContent = !!data.story || data.albumPhotos.length > 0;

  const shareTitle = lang === "zh" ? `${data.petName}的纪念` : `${data.petName}'s keepsake`;
  const shareText = data.memorialSentence ?? (lang === "zh"
    ? `来看看${data.petName}留在留光的纪念`
    : `A gentle memorial for ${data.petName} on Pawlight`);

  return (
    <div style={{ background: "#f7f1e8" }}>

      {/* ════════════════════════════════════════════════════════════════════
          HERO — occupies full first screen
          Layer 0: botanical atmosphere image (full bleed)
          Layer 1: gradient fade to page bg at bottom
          Layer 2: photo + name + sentence + HUG (in-hero, not below)
      ════════════════════════════════════════════════════════════════════ */}
      <section
        className="h5-hero relative w-full overflow-hidden flex flex-col"
        aria-label={t(lang, "纪念首屏", "Memorial")}
      >
        {/* ── Background botanical image ── */}
        <div className="absolute inset-0">
          <Image
            src="/h5-bg-page.jpg"
            alt=""
            fill
            className="object-cover object-top"
            sizes="100vw"
            priority
          />
          {/* Fade bottom to page bg so content section merges naturally */}
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom," +
                "rgba(247,241,232,0.08) 0%," +
                "rgba(247,241,232,0.15) 35%," +
                "rgba(247,241,232,0.72) 65%," +
                "rgba(247,241,232,0.97) 85%," +
                "#f7f1e8 100%)",
            }}
          />
        </div>

        {/* ── Hero content ── */}
        <div
          className="relative flex-1 flex flex-col items-center text-center"
          style={{
            paddingTop: "max(calc(env(safe-area-inset-top, 0px) + 36px), 56px)",
            paddingLeft: "24px",
            paddingRight: "24px",
          }}
        >
          {/* Botanical ring + pet photo */}
          <div className="relative flex-shrink-0" style={{ width: "260px", height: "196px" }}>
            {/* Ring decoration image — landscape aspect, circle centred */}
            <Image
              src="/h5-hero-ring.png"
              alt=""
              fill
              className="object-contain"
              sizes="260px"
              priority
            />
            {/* Pet photo — circular, sits inside ring centre
                Adjust top/width/height if ring image proportions differ */}
            <div
              className="absolute rounded-full overflow-hidden"
              style={{
                width: "140px",
                height: "140px",
                top: "4px",
                left: "50%",
                transform: "translateX(-50%)",
                zIndex: 1,
                boxShadow: "0 3px 18px rgba(0,0,0,0.10)",
              }}
            >
              {data.mainPhoto ? (
                <Image
                  src={data.mainPhoto}
                  alt={t(lang, `${data.petName}的主照片`, `${data.petName}'s photo`)}
                  fill
                  className="object-cover"
                  sizes="140px"
                  priority
                />
              ) : (
                <div
                  className="w-full h-full flex items-center justify-center"
                  style={{ background: "#dfd9d0" }}
                  aria-label={t(lang, "暂无照片", "No photo")}
                >
                  <span style={{ fontSize: "34px" }}>🐾</span>
                </div>
              )}
            </div>
          </div>

          {/* Pet name — the anchor; keep it warm, not harsh */}
          <h1
            style={{
              fontFamily: "Georgia, 'Noto Serif SC', serif",
              fontSize: "clamp(24px, 7vw, 32px)",
              fontWeight: 600,
              color: "#2c2c2c",
              marginTop: "18px",
              lineHeight: 1.2,
              letterSpacing: "0.03em",
            }}
          >
            {data.petName}
          </h1>

          {/* Dates */}
          {datesLine && (
            <p
              style={{
                fontSize: "12px",
                color: "#a89e94",
                marginTop: "6px",
                letterSpacing: "0.05em",
              }}
            >
              {datesLine}
            </p>
          )}

          {/* Memorial sentence */}
          {data.memorialSentence && (
            <p
              style={{
                fontFamily: "Georgia, serif",
                fontStyle: "italic",
                fontSize: "15px",
                color: "#6e6258",
                lineHeight: "1.85",
                marginTop: "14px",
                maxWidth: "280px",
              }}
            >
              {data.memorialSentence}
            </p>
          )}

          {/* Provenance label */}
          <p
            style={{
              fontSize: "11px",
              color: "#b4aca4",
              marginTop: "8px",
              letterSpacing: "0.07em",
            }}
          >
            {t(lang, "✦ 来自主人的一页纪念", "✦ A keepsake from their person")}
          </p>

          {/* ── Hug section — front and centre, still in hero ── */}
          <div
            style={{
              width: "100%",
              maxWidth: "320px",
              marginTop: "30px",
              paddingBottom: "36px",
            }}
          >
            <HugSection
              slug={slug}
              initialHugCount={data.hugCount}
              hugEnabled={data.hugEnabled}
              lang={lang}
            />
          </div>
        </div>

        {/* Scroll hint — only when there is content below */}
        {hasContent && (
          <div
            className="relative flex flex-col items-center"
            style={{ paddingBottom: "22px" }}
          >
            <p
              style={{
                fontSize: "11px",
                color: "#b4aca4",
                letterSpacing: "0.06em",
              }}
            >
              {t(lang, "↓ 看看TA的回忆", "↓ Scroll to their memories")}
            </p>
          </div>
        )}
      </section>

      {/* ════════════════════════════════════════════════════════════════════
          MEMORY CONTENT — story + photos
          Each card uses a botanical image as texture background
      ════════════════════════════════════════════════════════════════════ */}
      {hasContent && (
        <div
          style={{
            padding: "4px 16px 0",
            display: "flex",
            flexDirection: "column",
            gap: "14px",
          }}
        >
          {/* ── Story card ── */}
          {data.story && (
            <article className="relative rounded-2xl overflow-hidden">
              {/* Botanical card texture */}
              <div className="absolute inset-0">
                <Image
                  src="/h5-card-story.jpg"
                  alt=""
                  fill
                  className="object-cover"
                  sizes="calc(100vw - 32px)"
                />
                <div
                  className="absolute inset-0"
                  style={{ background: "rgba(252,249,245,0.91)" }}
                />
              </div>
              {/* Content */}
              <div className="relative" style={{ padding: "20px" }}>
                <header
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "7px",
                    marginBottom: "14px",
                  }}
                >
                  <IconLeaf />
                  <span
                    style={{
                      fontSize: "13px",
                      fontWeight: 500,
                      color: "#526744",
                      letterSpacing: "0.04em",
                    }}
                  >
                    {t(lang, "TA的故事", "Their Story")}
                  </span>
                </header>
                <p
                  style={{
                    fontSize: "14px",
                    color: "#3a3530",
                    lineHeight: "1.95",
                    whiteSpace: "pre-wrap",
                    wordBreak: "break-word",
                  }}
                >
                  {data.story}
                </p>
              </div>
            </article>
          )}

          {/* ── Photo memories ── */}
          {data.albumPhotos.length > 0 && (
            <section>
              <header
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "7px",
                  marginBottom: "12px",
                  paddingLeft: "2px",
                }}
              >
                <IconPhoto />
                <span
                  style={{
                    fontSize: "13px",
                    fontWeight: 500,
                    color: "#526744",
                    letterSpacing: "0.04em",
                  }}
                >
                  {t(lang, "照片回忆", "Photo Memories")}
                </span>
              </header>
              <PhotoSection photos={data.albumPhotos} />
            </section>
          )}
        </div>
      )}

      {/* ════════════════════════════════════════════════════════════════════
          CLOSING — emotional end-of-page; botanical wide card as bg
      ════════════════════════════════════════════════════════════════════ */}
      <footer
        className="relative overflow-hidden"
        style={{ marginTop: "20px", minHeight: "280px" }}
      >
        {/* Botanical horizontal card */}
        <div className="absolute inset-0">
          <Image
            src="/h5-card-wide.jpg"
            alt=""
            fill
            className="object-cover object-center"
            sizes="100vw"
          />
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom," +
                "#f7f1e8 0%," +
                "rgba(247,241,232,0.55) 22%," +
                "rgba(247,241,232,0.55) 72%," +
                "rgba(247,241,232,0.92) 100%)",
            }}
          />
        </div>

        {/* Closing content */}
        <div
          className="relative flex flex-col items-center text-center"
          style={{
            padding: "44px 32px 0",
            paddingBottom:
              "max(calc(env(safe-area-inset-bottom, 0px) + 44px), 56px)",
          }}
        >
          <h2
            style={{
              fontFamily: "Georgia, 'Noto Serif SC', serif",
              fontSize: "20px",
              fontWeight: 500,
              color: "#2c2c2c",
              letterSpacing: "0.04em",
            }}
          >
            {t(lang, "谢谢你来看TA", "Thank you for visiting")}
          </h2>

          <p
            style={{
              fontSize: "14px",
              color: "#8a8078",
              marginTop: "10px",
              lineHeight: "1.85",
            }}
          >
            {t(lang, "TA在这里被爱着，", "They are loved here,")}
            <br />
            {t(lang, "也因为你而被记得。", "and remembered because of you.")}
          </p>

          <div style={{ marginTop: "22px" }}>
            <ShareButton title={shareTitle} text={shareText} lang={lang} />
          </div>

          {/* Soft rule */}
          <div
            style={{
              width: "28px",
              height: "1px",
              background: "rgba(138,128,120,0.22)",
              margin: "26px auto 18px",
            }}
          />

          <p
            style={{
              fontSize: "12px",
              color: "#a89e94",
              letterSpacing: "0.07em",
            }}
          >
            {t(lang, "❧ 这份想念，会一直留在这里 ❧", "❧ This love will always be here ❧")}
          </p>

          <p
            style={{
              fontSize: "11px",
              color: "#8a8078",
              opacity: 0.26,
              marginTop: "32px",
              letterSpacing: "0.04em",
            }}
          >
            {t(lang, "由留光生成", "Made with Pawlight")}
          </p>
        </div>
      </footer>
    </div>
  );
}
