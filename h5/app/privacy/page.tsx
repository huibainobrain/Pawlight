import type { Metadata } from "next";
import Link from "next/link";
import { SUPPORT_EMAIL } from "@/lib/config";

type Lang = "en" | "zh";

export const metadata: Metadata = {
  title: "Privacy Policy — Pawlight",
};

interface LegalSection {
  title: string;
  body: React.ReactNode;
}

interface LegalCopy {
  h1: string;
  updatedLabel: string;
  updated: string;
  intro: React.ReactNode;
  sections: LegalSection[];
}

const COPY: Record<Lang, LegalCopy> = {
  en: {
    h1: "Privacy Policy",
    updatedLabel: "Last updated",
    updated: "July 7, 2026",
    intro: (
      <>
        Pawlight (&ldquo;the App&rdquo;) is operated by an independent
        developer. This policy explains how we collect, use, and protect
        your personal information. By using the App, you agree to this
        policy.
      </>
    ),
    sections: [
      {
        title: "1. Information We Collect",
        body: (
          <ul className="list-disc list-inside space-y-2">
            <li>
              <strong>Account information</strong>: When you sign in with
              Apple, we only receive the user identifier Apple provides (no
              real name or email, unless you choose to share it).
            </li>
            <li>
              <strong>Pet information</strong>: The pet name, photos,
              stories, and memorial sentence you choose to add.
            </li>
            <li>
              <strong>Visitor interactions</strong>: Hugs left by visitors
              on a shared memorial page (visitor nickname only, and may be
              anonymous).
            </li>
            <li>
              <strong>Device information</strong>: Basic technical
              information such as OS version, used for troubleshooting.
            </li>
          </ul>
        ),
      },
      {
        title: "2. How We Use Information",
        body: (
          <>
            <p>We use the information we collect to:</p>
            <ul className="list-disc list-inside space-y-1 mt-2">
              <li>Provide, maintain, and improve the App&apos;s features</li>
              <li>Display the memorial content you create</li>
              <li>Verify in-app purchases</li>
              <li>Troubleshoot technical issues</li>
            </ul>
            <p className="mt-3">
              We do not sell, rent, or otherwise commercially transfer your
              personal information to third parties.
            </p>
          </>
        ),
      },
      {
        title: "3. Photos and Media",
        body: (
          <p>
            Photos you upload are stored in an encrypted cloud storage
            service (Cloudflare R2). Photos are only visible to others
            through a link you choose to share. You can delete photos in
            the App at any time.
          </p>
        ),
      },
      {
        title: "4. Information Sharing",
        body: (
          <>
            <p>
              We do not share your personal information with third parties,
              except:
            </p>
            <ul className="list-disc list-inside space-y-1 mt-2">
              <li>With your explicit consent</li>
              <li>When required by law</li>
              <li>
                With infrastructure providers necessary to operate the
                service (under data processing agreements)
              </li>
            </ul>
            <p className="mt-3">
              Third-party services used by the App include: Apple
              (sign-in), Railway (server hosting), Cloudflare R2 (file
              storage), and Vercel (web hosting).
            </p>
          </>
        ),
      },
      {
        title: "5. Data Security",
        body: (
          <p>
            We take reasonable technical measures to protect your data,
            including HTTPS encryption, access controls, and periodic
            security reviews. Please note that no method of transmission
            over the internet can be guaranteed 100% secure.
          </p>
        ),
      },
      {
        title: "6. Data Retention and Deletion",
        body: (
          <p>
            You can request account deletion at any time from the
            &ldquo;Me&rdquo; tab in the App. After deletion, we will remove
            all your personal data within 30 days, except where retention
            is required by law.
          </p>
        ),
      },
      {
        title: "7. Children's Privacy",
        body: (
          <p>
            The App is not directed at children under 13. If we discover we
            have inadvertently collected personal information from a
            child, we will delete it promptly.
          </p>
        ),
      },
      {
        title: "8. Policy Updates",
        body: (
          <p>
            We may update this privacy policy from time to time. We will
            notify you in the App when it changes, and will give at least
            7 days&apos; notice before material changes take effect.
          </p>
        ),
      },
      {
        title: "9. Contact Us",
        body: (
          <>
            <p>
              If you have any privacy-related questions, please contact us:
            </p>
            <p className="mt-2">
              Email:{" "}
              <a href={`mailto:${SUPPORT_EMAIL}`} style={{ color: "#526744" }}>
                {SUPPORT_EMAIL}
              </a>
            </p>
          </>
        ),
      },
    ],
  },
  zh: {
    h1: "隐私政策",
    updatedLabel: "最后更新",
    updated: "2026 年 7 月 7 日",
    intro: (
      <>
        Pawlight（以下简称“本应用”）由个人开发者运营。本政策说明我们如何收集、使用和保护您的个人信息。使用本应用即表示您同意本政策。
      </>
    ),
    sections: [
      {
        title: "一、我们收集的信息",
        body: (
          <ul className="list-disc list-inside space-y-2">
            <li>
              <strong>账号信息</strong>
              ：通过 Sign in with Apple
              登录时，我们仅接收 Apple
              提供的用户标识符（不包含真实姓名或邮箱，除非您主动授权）。
            </li>
            <li>
              <strong>宠物信息</strong>
              ：您主动填写的宠物名称、照片、故事、纪念语等内容。
            </li>
            <li>
              <strong>访客互动</strong>
              ：访问分享页面的访客留下的抱抱记录（仅包含访客昵称，可匿名）。
            </li>
            <li>
              <strong>设备信息</strong>
              ：操作系统版本等基本技术信息，用于排查问题。
            </li>
          </ul>
        ),
      },
      {
        title: "二、信息的使用",
        body: (
          <>
            <p>我们使用收集的信息用于：</p>
            <ul className="list-disc list-inside space-y-1 mt-2">
              <li>提供、维护和改进本应用的功能</li>
              <li>展示您创建的宠物纪念内容</li>
              <li>处理付费功能的购买验证</li>
              <li>排查技术故障</li>
            </ul>
            <p className="mt-3">
              我们不会将您的个人信息出售、出租或以任何商业方式转让给第三方。
            </p>
          </>
        ),
      },
      {
        title: "三、照片与媒体内容",
        body: (
          <p>
            您上传的照片存储在加密的云存储服务（Cloudflare
            R2）中。照片仅在您选择分享时，通过您提供的链接对他人可见。您可以随时在应用内删除照片。
          </p>
        ),
      },
      {
        title: "四、信息共享",
        body: (
          <>
            <p>我们不与第三方共享您的个人信息，以下情况除外：</p>
            <ul className="list-disc list-inside space-y-1 mt-2">
              <li>经您明确同意</li>
              <li>法律法规要求</li>
              <li>服务运营所必需的基础设施提供商（数据处理协议约束下）</li>
            </ul>
            <p className="mt-3">
              本应用使用的第三方服务包括：Apple（登录验证）、Railway（服务器托管）、Cloudflare
              R2（文件存储）、Vercel（网页托管）。
            </p>
          </>
        ),
      },
      {
        title: "五、数据安全",
        body: (
          <p>
            我们采取合理的技术措施保护您的数据，包括 HTTPS
            传输加密、访问控制和定期安全审查。但请注意，互联网传输不能保证
            100% 安全。
          </p>
        ),
      },
      {
        title: "六、数据留存与删除",
        body: (
          <p>
            您可以随时在应用内的“我的”页面申请注销账号，注销后我们将在 30
            天内删除您的所有个人数据（法律要求保留的除外）。
          </p>
        ),
      },
      {
        title: "七、儿童隐私",
        body: (
          <p>
            本应用不面向 13
            岁以下儿童。如果我们发现误收集了儿童个人信息，会立即删除。
          </p>
        ),
      },
      {
        title: "八、政策更新",
        body: (
          <p>
            我们可能不定期更新本隐私政策。更新后我们会在应用内通知，重大变更会在生效前
            7 天提前告知。
          </p>
        ),
      },
      {
        title: "九、联系我们",
        body: (
          <>
            <p>如有任何隐私相关问题，请通过以下方式联系我们：</p>
            <p className="mt-2">
              邮箱：
              <a href={`mailto:${SUPPORT_EMAIL}`} style={{ color: "#526744" }}>
                {SUPPORT_EMAIL}
              </a>
            </p>
          </>
        ),
      },
    ],
  },
};

export default async function PrivacyPage({
  searchParams,
}: {
  searchParams: Promise<{ lang?: string }>;
}) {
  const { lang: rawLang } = await searchParams;
  const lang: Lang = rawLang === "zh" ? "zh" : "en";
  const c = COPY[lang];

  return (
    <main
      className="max-w-2xl mx-auto px-5 py-12 text-sm leading-relaxed"
      style={{ color: "#2c2c2c" }}
    >
      <div className="flex items-center justify-between mb-8">
        <Link
          href="/"
          className="text-sm font-medium"
          style={{ color: "#526744", fontFamily: "Georgia, serif" }}
        >
          Pawlight
        </Link>
        <div className="flex items-center gap-1 text-xs">
          <Link
            href="/privacy"
            className="px-2.5 py-1 rounded-full transition-colors"
            style={{
              color: lang === "en" ? "#ffffff" : "#8a8078",
              background: lang === "en" ? "#526744" : "transparent",
            }}
          >
            EN
          </Link>
          <Link
            href="/privacy?lang=zh"
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

      <h1
        className="text-2xl font-semibold mb-1"
        style={{ fontFamily: "Georgia, serif" }}
      >
        {c.h1}
      </h1>
      <p className="mb-8" style={{ color: "#8a8078" }}>
        {c.updatedLabel}: {c.updated}
      </p>

      <p className="mb-6">{c.intro}</p>

      {c.sections.map((section) => (
        <section className="mb-8" key={section.title}>
          <h2
            className="text-base font-semibold mb-3"
            style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
          >
            {section.title}
          </h2>
          {section.body}
        </section>
      ))}
    </main>
  );
}
