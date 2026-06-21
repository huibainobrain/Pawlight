import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "隐私政策 — 星屿纪念",
};

export default function PrivacyPage() {
  const updated = "2026 年 6 月 21 日";
  const contact = "ntuwangyiming@gmail.com";

  return (
    <main className="max-w-2xl mx-auto px-5 py-12 text-sm leading-relaxed" style={{ color: "#2c2c2c" }}>
      <h1
        className="text-2xl font-semibold mb-1"
        style={{ fontFamily: "Georgia, serif" }}
      >
        隐私政策
      </h1>
      <p className="mb-8" style={{ color: "#8a8078" }}>
        最后更新：{updated}
      </p>

      <p className="mb-6">
        星屿纪念（以下简称"本应用"）由个人开发者运营。本政策说明我们如何收集、使用和保护您的个人信息。使用本应用即表示您同意本政策。
      </p>

      <Section title="一、我们收集的信息">
        <ul className="list-disc list-inside space-y-2">
          <li>
            <strong>账号信息</strong>：通过 Sign in with Apple 登录时，我们仅接收 Apple 提供的用户标识符（不包含真实姓名或邮箱，除非您主动授权）。
          </li>
          <li>
            <strong>宠物信息</strong>：您主动填写的宠物名称、照片、故事、纪念语等内容。
          </li>
          <li>
            <strong>访客互动</strong>：访问分享页面的访客留下的抱抱记录（仅包含访客昵称，可匿名）。
          </li>
          <li>
            <strong>设备信息</strong>：操作系统版本等基本技术信息，用于排查问题。
          </li>
        </ul>
      </Section>

      <Section title="二、信息的使用">
        <p>我们使用收集的信息用于：</p>
        <ul className="list-disc list-inside space-y-1 mt-2">
          <li>提供、维护和改进本应用的功能</li>
          <li>展示您创建的宠物纪念内容</li>
          <li>处理付费功能的购买验证</li>
          <li>排查技术故障</li>
        </ul>
        <p className="mt-3">我们不会将您的个人信息出售、出租或以任何商业方式转让给第三方。</p>
      </Section>

      <Section title="三、照片与媒体内容">
        <p>
          您上传的照片存储在加密的云存储服务（Cloudflare R2）中。照片仅在您选择分享时，通过您提供的链接对他人可见。您可以随时在应用内删除照片。
        </p>
      </Section>

      <Section title="四、信息共享">
        <p>我们不与第三方共享您的个人信息，以下情况除外：</p>
        <ul className="list-disc list-inside space-y-1 mt-2">
          <li>经您明确同意</li>
          <li>法律法规要求</li>
          <li>服务运营所必需的基础设施提供商（数据处理协议约束下）</li>
        </ul>
        <p className="mt-3">
          本应用使用的第三方服务包括：Apple（登录验证）、Railway（服务器托管）、Cloudflare R2（文件存储）、Vercel（网页托管）。
        </p>
      </Section>

      <Section title="五、数据安全">
        <p>
          我们采取合理的技术措施保护您的数据，包括 HTTPS 传输加密、访问控制和定期安全审查。但请注意，互联网传输不能保证 100% 安全。
        </p>
      </Section>

      <Section title="六、数据留存与删除">
        <p>
          您可以随时在应用内的"我的"页面申请注销账号，注销后我们将在 30 天内删除您的所有个人数据（法律要求保留的除外）。
        </p>
      </Section>

      <Section title="七、儿童隐私">
        <p>
          本应用不面向 13 岁以下儿童。如果我们发现误收集了儿童个人信息，会立即删除。
        </p>
      </Section>

      <Section title="八、政策更新">
        <p>
          我们可能不定期更新本隐私政策。更新后我们会在应用内通知，重大变更会在生效前 7 天提前告知。
        </p>
      </Section>

      <Section title="九、联系我们">
        <p>
          如有任何隐私相关问题，请通过以下方式联系我们：
        </p>
        <p className="mt-2">
          邮箱：
          <a href={`mailto:${contact}`} style={{ color: "#526744" }}>
            {contact}
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
