import type { Metadata } from "next";
import { SUPPORT_EMAIL } from "@/lib/config";

export const metadata: Metadata = {
  title: "服务条款 — Pawlight",
};

export default function TermsPage() {
  const updated = "2026 年 7 月 7 日";

  return (
    <main className="max-w-2xl mx-auto px-5 py-12 text-sm leading-relaxed" style={{ color: "#2c2c2c" }}>
      <h1
        className="text-2xl font-semibold mb-1"
        style={{ fontFamily: "Georgia, serif" }}
      >
        服务条款
      </h1>
      <p className="mb-8" style={{ color: "#8a8078" }}>
        最后更新：{updated}
      </p>

      <p className="mb-6">
        欢迎使用 Pawlight（以下简称“本应用”）。本应用由个人开发者运营，是一款用于纪念宠物的应用。使用本应用即表示您同意以下条款。
      </p>

      <Section title="一、服务说明">
        <p>
          Pawlight 为用户提供创建宠物纪念空间的功能，包括保存故事与照片、书写私密的信件，以及生成可分享的纪念页面。本应用不提供医疗、法律或宗教相关的建议或服务。
        </p>
      </Section>

      <Section title="二、账号">
        <p>
          本应用通过 Sign in with Apple 进行登录。您需要对自己账号下的所有操作负责。V1 阶段每个账号仅支持创建一个宠物纪念空间。
        </p>
      </Section>

      <Section title="三、用户内容">
        <p>
          您上传或撰写的照片、故事、信件等内容归您所有。为了提供保存与展示服务，您授权本应用在必要范围内存储、处理和展示这些内容——展示范围以您在应用内设置的可见性（仅自己可见 / 通过链接可见）为准。私密的信件不会出现在任何分享出去的纪念页面中。
        </p>
        <p className="mt-3">
          请不要上传您无权使用的内容，或包含违法、侵权、辱骂性质的内容。我们保留在发现此类内容时移除的权利。
        </p>
      </Section>

      <Section title="四、购买内容">
        <p>
          本应用提供免费方案与「完整纪念空间」一次性购买方案。所有购买均通过 App Store 完成结算，退款请依据 Apple 的退款政策，通过 App Store 提交申请。购买内容为解锁应用内的额外功能，不涉及实体商品配送。
        </p>
      </Section>

      <Section title="五、可接受使用">
        <p>
          请不要将本应用用于任何违反当地法律法规的用途，也不要尝试干扰、破坏本应用的正常运行或未经授权访问其他用户的数据。
        </p>
      </Section>

      <Section title="六、服务的可用性">
        <p>
          我们努力保持本应用的稳定运行，但不保证服务不会中断或没有错误。本应用按“现状”提供，若因维护、故障或不可抗力导致服务暂时不可用，我们会尽快恢复。
        </p>
      </Section>

      <Section title="七、条款变更">
        <p>
          我们可能不定期更新本服务条款。更新后我们会在应用内通知，重大变更会在生效前 7 天提前告知。继续使用本应用即表示您接受更新后的条款。
        </p>
      </Section>

      <Section title="八、联系我们">
        <p>如有任何关于本条款的问题，请通过以下方式联系我们：</p>
        <p className="mt-2">
          邮箱：
          <a href={`mailto:${SUPPORT_EMAIL}`} style={{ color: "#526744" }}>
            {SUPPORT_EMAIL}
          </a>
        </p>
      </Section>
    </main>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-8">
      <h2
        className="text-base font-semibold mb-3"
        style={{ fontFamily: "Georgia, serif" }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
