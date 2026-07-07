import type { Metadata } from "next";
import Link from "next/link";
import { SUPPORT_EMAIL } from "@/lib/config";

type Lang = "en" | "zh";

export const metadata: Metadata = {
  title: "Terms of Service — Pawlight",
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
    h1: "Terms of Service",
    updatedLabel: "Last updated",
    updated: "July 7, 2026",
    intro: (
      <>
        Welcome to Pawlight (&ldquo;the App&rdquo;). The App is operated by
        an independent developer and is a memorial app for pets. By using
        the App, you agree to the following terms.
      </>
    ),
    sections: [
      {
        title: "1. Description of the Service",
        body: (
          <p>
            Pawlight lets you create a memorial space for your pet,
            including saving stories and photos, writing private letters,
            and generating a shareable memorial page. The App does not
            provide medical, legal, or religious advice or services.
          </p>
        ),
      },
      {
        title: "2. Account",
        body: (
          <p>
            The App uses Sign in with Apple for authentication. You are
            responsible for all activity under your account. In the V1
            release, each account supports creating one pet memorial
            space.
          </p>
        ),
      },
      {
        title: "3. User Content",
        body: (
          <>
            <p>
              You own the photos, stories, letters, and other content you
              upload or write. To provide the storage and display service,
              you grant the App a license to store, process, and display
              this content as needed — the extent of display follows the
              visibility you set in the App (private / visible by link).
              Private letters never appear on any shared memorial page.
            </p>
            <p className="mt-3">
              Please do not upload content you do not have the right to
              use, or content that is illegal, infringing, or abusive. We
              reserve the right to remove such content if we become aware
              of it.
            </p>
          </>
        ),
      },
      {
        title: "4. Purchases",
        body: (
          <p>
            The App offers a free plan and a one-time purchase to unlock
            the Full Memorial Space. All purchases are billed through the
            App Store; refunds follow Apple&apos;s refund policy and
            should be requested through the App Store. Purchases unlock
            additional in-app features and do not involve the delivery of
            any physical goods.
          </p>
        ),
      },
      {
        title: "5. Acceptable Use",
        body: (
          <p>
            Please do not use the App for any purpose that violates
            applicable laws, or attempt to interfere with, disrupt, or
            gain unauthorized access to other users&apos; data.
          </p>
        ),
      },
      {
        title: "6. Service Availability",
        body: (
          <p>
            We work to keep the App running reliably, but we do not
            guarantee the service will be uninterrupted or error-free. The
            App is provided &ldquo;as is.&rdquo; If the service becomes
            temporarily unavailable due to maintenance, a fault, or events
            beyond our control, we will work to restore it as soon as
            possible.
          </p>
        ),
      },
      {
        title: "7. Changes to These Terms",
        body: (
          <p>
            We may update these terms from time to time. We will notify
            you in the App when they change, and will give at least 7
            days&apos; notice before material changes take effect.
            Continued use of the App after changes take effect constitutes
            acceptance of the updated terms.
          </p>
        ),
      },
      {
        title: "8. Contact Us",
        body: (
          <>
            <p>
              If you have any questions about these terms, please contact
              us:
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
    h1: "服务条款",
    updatedLabel: "最后更新",
    updated: "2026 年 7 月 7 日",
    intro: (
      <>
        欢迎使用 Pawlight（以下简称“本应用”）。本应用由个人开发者运营，是一款用于纪念宠物的应用。使用本应用即表示您同意以下条款。
      </>
    ),
    sections: [
      {
        title: "一、服务说明",
        body: (
          <p>
            Pawlight
            为用户提供创建宠物纪念空间的功能，包括保存故事与照片、书写私密的信件，以及生成可分享的纪念页面。本应用不提供医疗、法律或宗教相关的建议或服务。
          </p>
        ),
      },
      {
        title: "二、账号",
        body: (
          <p>
            本应用通过 Sign in with Apple
            进行登录。您需要对自己账号下的所有操作负责。V1
            阶段每个账号仅支持创建一个宠物纪念空间。
          </p>
        ),
      },
      {
        title: "三、用户内容",
        body: (
          <>
            <p>
              您上传或撰写的照片、故事、信件等内容归您所有。为了提供保存与展示服务，您授权本应用在必要范围内存储、处理和展示这些内容——展示范围以您在应用内设置的可见性（仅自己可见
              / 通过链接可见）为准。私密的信件不会出现在任何分享出去的纪念页面中。
            </p>
            <p className="mt-3">
              请不要上传您无权使用的内容，或包含违法、侵权、辱骂性质的内容。我们保留在发现此类内容时移除的权利。
            </p>
          </>
        ),
      },
      {
        title: "四、购买内容",
        body: (
          <p>
            本应用提供免费方案与「完整纪念空间」一次性购买方案。所有购买均通过
            App Store 完成结算，退款请依据 Apple 的退款政策，通过 App Store
            提交申请。购买内容为解锁应用内的额外功能，不涉及实体商品配送。
          </p>
        ),
      },
      {
        title: "五、可接受使用",
        body: (
          <p>
            请不要将本应用用于任何违反当地法律法规的用途，也不要尝试干扰、破坏本应用的正常运行或未经授权访问其他用户的数据。
          </p>
        ),
      },
      {
        title: "六、服务的可用性",
        body: (
          <p>
            我们努力保持本应用的稳定运行，但不保证服务不会中断或没有错误。本应用按“现状”提供，若因维护、故障或不可抗力导致服务暂时不可用，我们会尽快恢复。
          </p>
        ),
      },
      {
        title: "七、条款变更",
        body: (
          <p>
            我们可能不定期更新本服务条款。更新后我们会在应用内通知，重大变更会在生效前
            7 天提前告知。继续使用本应用即表示您接受更新后的条款。
          </p>
        ),
      },
      {
        title: "八、联系我们",
        body: (
          <>
            <p>如有任何关于本条款的问题，请通过以下方式联系我们：</p>
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

export default async function TermsPage({
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
            href="/terms"
            className="px-2.5 py-1 rounded-full transition-colors"
            style={{
              color: lang === "en" ? "#ffffff" : "#8a8078",
              background: lang === "en" ? "#526744" : "transparent",
            }}
          >
            EN
          </Link>
          <Link
            href="/terms?lang=zh"
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
