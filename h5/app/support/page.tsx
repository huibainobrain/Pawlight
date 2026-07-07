import type { Metadata } from "next";
import Link from "next/link";
import { SUPPORT_EMAIL } from "@/lib/config";

type Lang = "en" | "zh";

export const metadata: Metadata = {
  title: "Pawlight Support",
  description:
    "Get help, contact support, and find privacy and terms information for Pawlight.",
};

interface Faq {
  q: string;
  a: string;
}

interface Copy {
  brand: string;
  h1: string;
  subtitle: string;
  description: string;
  contactTitle: string;
  contactBody: string;
  emailLabel: string;
  ctaButton: string;
  responseTitle: string;
  responseBody: string;
  includeTitle: string;
  includeBody: string;
  includeItems: string[];
  faqTitle: string;
  faqs: Faq[];
  privacyTitle: string;
  privacyBody: string;
  privacyLinkLabel: string;
  termsLinkLabel: string;
  footerLine1: string;
  footerLine2: string;
  homeLabel: string;
}

const COPY: Record<Lang, Copy> = {
  en: {
    brand: "Pawlight",
    h1: "Pawlight Support",
    subtitle: "Help, feedback, and support for Pawlight.",
    description:
      "Pawlight is a gentle memorial app for the pets we love and remember.",
    contactTitle: "Contact Support",
    contactBody:
      "If you need help with Pawlight, have feedback, or want to report an issue, please contact us by email.",
    emailLabel: "Email",
    ctaButton: "Email Support",
    responseTitle: "Response time",
    responseBody: "We usually respond within 3–5 business days.",
    includeTitle: "What to include",
    includeBody:
      "To help us understand your issue, please include:",
    includeItems: [
      "Your device model",
      "Your iOS version",
      "Your Pawlight app version",
      "A short description of what happened",
      "Screenshots, if helpful",
    ],
    faqTitle: "Common help topics",
    faqs: [
      {
        q: "Account and sign-in",
        a: "Pawlight uses Apple sign-in where available. If you have trouble signing in, please contact us with your device model and iOS version.",
      },
      {
        q: "Memorial visibility",
        a: "You can keep a memorial private or make it visible by link. Private letters are never shown on shared memorial pages.",
      },
      {
        q: "Shared memorial pages",
        a: "If a shared memorial page is unavailable, the owner may have changed the visibility settings or the link may no longer be valid.",
      },
      {
        q: "Letters to Them",
        a: "Private letters stay only with you and do not appear on shared memorial pages.",
      },
      {
        q: "Photo memories",
        a: "Photos added to a memorial may appear on the shared memorial page if the memorial is visible by link.",
      },
    ],
    privacyTitle: "Privacy & Terms",
    privacyBody:
      "You can review Pawlight's privacy policy and terms of service here.",
    privacyLinkLabel: "Privacy Policy",
    termsLinkLabel: "Terms of Service",
    footerLine1: "Pawlight",
    footerLine2: "A gentle place for pet memories.",
    homeLabel: "Home",
  },
  zh: {
    brand: "Pawlight",
    h1: "Pawlight 支持",
    subtitle: "获取帮助、反馈问题，或联系我们。",
    description: "Pawlight 是一个温柔的宠物纪念应用，献给我们记得的TA。",
    contactTitle: "联系支持",
    contactBody:
      "如果你在使用 Pawlight 时遇到问题，或希望提交反馈，请通过邮件联系我们。",
    emailLabel: "邮箱",
    ctaButton: "发邮件联系支持",
    responseTitle: "响应时间",
    responseBody: "我们通常会在 3–5 个工作日内回复。",
    includeTitle: "需要包含的信息",
    includeBody: "为了帮助我们更快定位问题，请在邮件中提供：",
    includeItems: [
      "设备型号",
      "iOS 版本",
      "Pawlight App 版本",
      "问题描述",
      "截图，如有",
    ],
    faqTitle: "常见问题",
    faqs: [
      {
        q: "账号与登录",
        a: "Pawlight 支持通过 Apple 登录。如果登录时遇到问题，请联系我们并提供设备型号和 iOS 版本。",
      },
      {
        q: "纪念页可见范围",
        a: "你可以将纪念页设置为仅自己可见，或通过链接对外可见。私密的信件不会出现在分享出去的纪念页中。",
      },
      {
        q: "分享的纪念页",
        a: "如果分享的纪念页无法打开，可能是主人更改了可见范围，或链接已经失效。",
      },
      {
        q: "写给TA的信",
        a: "写给TA的信只有你自己能看到，不会出现在分享出去的纪念页中。",
      },
      {
        q: "照片回忆",
        a: "添加到纪念页的照片，在纪念页设置为通过链接可见时，可能会显示在分享页面中。",
      },
    ],
    privacyTitle: "隐私与条款",
    privacyBody: "你可以在这里查看 Pawlight 的隐私政策和服务条款。",
    privacyLinkLabel: "隐私政策",
    termsLinkLabel: "服务条款",
    footerLine1: "Pawlight 留光",
    footerLine2: "为我们记得的TA，留一个温柔的地方。",
    homeLabel: "首页",
  },
};

export default async function SupportPage({
  searchParams,
}: {
  searchParams: Promise<{ lang?: string }>;
}) {
  const { lang: rawLang } = await searchParams;
  const lang: Lang = rawLang === "zh" ? "zh" : "en";
  const c = COPY[lang];
  const year = new Date().getFullYear();

  const mailSubject = encodeURIComponent("Pawlight Support Request");
  const mailBody = encodeURIComponent(
    "Hi Pawlight Support,\n\nI need help with:\n\nDevice:\niOS version:\nApp version:\nIssue description:\n"
  );
  const mailtoHref = `mailto:${SUPPORT_EMAIL}?subject=${mailSubject}&body=${mailBody}`;

  return (
    <main className="min-h-screen px-5 py-10 md:py-16">
      <div className="max-w-2xl mx-auto">
        {/* Top bar: brand + language switch */}
        <div className="flex items-center justify-between mb-10">
          <Link
            href="/"
            className="text-sm font-medium"
            style={{ color: "#526744", fontFamily: "Georgia, serif" }}
          >
            {c.brand}
          </Link>
          <div className="flex items-center gap-1 text-xs">
            <Link
              href="/support"
              className="px-2.5 py-1 rounded-full transition-colors"
              style={{
                color: lang === "en" ? "#ffffff" : "#8a8078",
                background: lang === "en" ? "#526744" : "transparent",
              }}
            >
              EN
            </Link>
            <Link
              href="/support?lang=zh"
              className="px-2.5 py-1 rounded-full transition-colors"
              style={{
                color: lang === "zh" ? "#ffffff" : "#8a8078",
                background: lang === "zh" ? "#526744" : "transparent",
              }}
            >
              中文
            </Link>
          </div>
        </div>

        {/* Header */}
        <header className="relative text-center mb-10">
          <div
            aria-hidden="true"
            className="absolute left-1/2 -translate-x-1/2 -top-10 -z-10"
            style={{
              width: 260,
              height: 260,
              borderRadius: "9999px",
              background:
                "radial-gradient(circle, rgba(126,147,102,0.16) 0%, rgba(126,147,102,0) 70%)",
            }}
          />
          <h1
            className="text-3xl font-semibold mb-2"
            style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
          >
            {c.h1}
          </h1>
          <p className="text-base mb-3" style={{ color: "#526744" }}>
            {c.subtitle}
          </p>
          <p
            className="text-sm max-w-md mx-auto leading-relaxed"
            style={{ color: "#8a8078" }}
          >
            {c.description}
          </p>
        </header>

        <div className="space-y-5">
          {/* Contact Support */}
          <Card>
            <SectionTitle id="contact">{c.contactTitle}</SectionTitle>
            <p
              className="text-sm leading-relaxed mb-4"
              style={{ color: "#5c5650" }}
            >
              {c.contactBody}
            </p>
            <p className="text-sm mb-5" style={{ color: "#8a8078" }}>
              {c.emailLabel}:{" "}
              <a
                href={`mailto:${SUPPORT_EMAIL}`}
                className="underline underline-offset-2"
                style={{ color: "#526744" }}
              >
                {SUPPORT_EMAIL}
              </a>
            </p>
            <a
              href={mailtoHref}
              className="inline-flex items-center justify-center w-full sm:w-auto rounded-full text-sm font-medium px-6 py-3 transition-opacity hover:opacity-90"
              style={{ background: "#526744", color: "#ffffff" }}
            >
              {c.ctaButton}
            </a>

            <div
              className="mt-5 pt-4"
              style={{ borderTop: "1px solid #e8e0d4" }}
            >
              <p className="text-xs font-medium mb-1" style={{ color: "#2c2c2c" }}>
                {c.responseTitle}
              </p>
              <p className="text-xs" style={{ color: "#8a8078" }}>
                {c.responseBody}
              </p>
            </div>
          </Card>

          {/* What to include */}
          <Card>
            <SectionTitle id="what-to-include">{c.includeTitle}</SectionTitle>
            <p
              className="text-sm leading-relaxed mb-3"
              style={{ color: "#5c5650" }}
            >
              {c.includeBody}
            </p>
            <ul className="space-y-1.5">
              {c.includeItems.map((item) => (
                <li
                  key={item}
                  className="text-sm flex items-start gap-2"
                  style={{ color: "#5c5650" }}
                >
                  <span style={{ color: "#7e9366" }} aria-hidden="true">
                    •
                  </span>
                  {item}
                </li>
              ))}
            </ul>
          </Card>

          {/* Common help topics */}
          <Card>
            <SectionTitle id="faq">{c.faqTitle}</SectionTitle>
            <div>
              {c.faqs.map((faq, i) => (
                <FaqRow
                  key={faq.q}
                  q={faq.q}
                  a={faq.a}
                  isLast={i === c.faqs.length - 1}
                />
              ))}
            </div>
          </Card>

          {/* Privacy & Terms */}
          <Card>
            <SectionTitle id="privacy-terms">{c.privacyTitle}</SectionTitle>
            <p
              className="text-sm leading-relaxed mb-4"
              style={{ color: "#5c5650" }}
            >
              {c.privacyBody}
            </p>
            <div className="flex flex-wrap gap-3">
              <Link
                href="/privacy"
                className="text-sm font-medium rounded-full px-4 py-2 transition-colors"
                style={{
                  color: "#526744",
                  border: "1px solid #e8e0d4",
                }}
              >
                {c.privacyLinkLabel}
              </Link>
              <Link
                href="/terms"
                className="text-sm font-medium rounded-full px-4 py-2 transition-colors"
                style={{
                  color: "#526744",
                  border: "1px solid #e8e0d4",
                }}
              >
                {c.termsLinkLabel}
              </Link>
            </div>
          </Card>
        </div>

        {/* Footer */}
        <footer className="text-center mt-14 mb-6">
          <p
            className="text-sm font-medium mb-1"
            style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
          >
            {c.footerLine1}
          </p>
          <p className="text-xs mb-4" style={{ color: "#8a8078" }}>
            {c.footerLine2}
          </p>
          <div
            className="flex items-center justify-center gap-4 text-xs mb-4"
            style={{ color: "#8a8078" }}
          >
            <Link href="/" className="underline underline-offset-2">
              {c.homeLabel}
            </Link>
            <Link href="/privacy" className="underline underline-offset-2">
              {c.privacyLinkLabel}
            </Link>
            <Link href="/terms" className="underline underline-offset-2">
              {c.termsLinkLabel}
            </Link>
          </div>
          <p className="text-xs" style={{ color: "#b0a89c" }}>
            © {year} Pawlight. All rights reserved.
          </p>
        </footer>
      </div>
    </main>
  );
}

// ── Local building blocks ──────────────────────────────────────────────────

function Card({ children }: { children: React.ReactNode }) {
  return (
    <section
      className="rounded-2xl p-6 md:p-7"
      style={{
        background: "#ffffff",
        border: "1px solid #e8e0d4",
        boxShadow: "0 8px 24px rgba(82,103,68,0.06)",
      }}
    >
      {children}
    </section>
  );
}

function SectionTitle({
  id,
  children,
}: {
  id: string;
  children: React.ReactNode;
}) {
  return (
    <h2
      id={id}
      className="text-lg font-semibold mb-3"
      style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
    >
      {children}
    </h2>
  );
}

function FaqRow({ q, a, isLast }: { q: string; a: string; isLast: boolean }) {
  return (
    <div
      className="py-4"
      style={
        !isLast ? { borderBottom: "1px solid #e8e0d4" } : { paddingBottom: 0 }
      }
    >
      <p className="text-sm font-medium mb-1.5" style={{ color: "#2c2c2c" }}>
        {q}
      </p>
      <p className="text-sm leading-relaxed" style={{ color: "#8a8078" }}>
        {a}
      </p>
    </div>
  );
}
