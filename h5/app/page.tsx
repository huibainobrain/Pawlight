export const dynamic = "force-dynamic";
export const revalidate = 0;

type Lang = "en" | "zh";

function t(lang: Lang, zh: string, en: string) {
  return lang === "zh" ? zh : en;
}

export default async function Home({
  searchParams,
}: {
  searchParams: Promise<{ lang?: string }>;
}) {
  const { lang: rawLang } = await searchParams;
  const lang: Lang = rawLang === "zh" ? "zh" : "en";

  return (
    <main className="flex flex-col items-center justify-center min-h-screen px-5 text-center">
      <p className="text-4xl mb-4">🌙</p>
      <h1
        className="text-2xl font-semibold mb-2"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        Pawlight
      </h1>
      <p className="text-sm" style={{ color: "#8a8078" }}>
        {t(lang, "为每一个离去的小生命，留下一颗永恒的星球", "A quiet place to keep their light")}
      </p>
    </main>
  );
}
