import { notFound } from "next/navigation";
import Image from "next/image";
import HugButton from "./HugButton";

const API = process.env.NEXT_PUBLIC_API_URL;

const PET_TYPE_LABEL: Record<string, string> = {
  CAT: "🐱",
  DOG: "🐶",
  OTHER: "🐾",
};

async function getShare(slug: string) {
  const res = await fetch(`${API}/api/v1/shares/${slug}`, {
    next: { revalidate: 60 },
  });
  if (!res.ok) return null;
  return res.json();
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const share = await getShare(slug);
  if (!share) return { title: "星屿纪念" };
  return {
    title: `${share.pet.name}的星球 · 星屿纪念`,
    description: share.pet.memorialSentence ?? `来看看${share.pet.name}的纪念星球`,
  };
}

export default async function SharePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const share = await getShare(slug);
  if (!share) notFound();

  const { pet } = share;
  const mainPhoto = pet.photos?.find((p: { id: string }) => p.id === pet.mainPhotoId) ?? pet.photos?.[0];

  return (
    <main className="max-w-md mx-auto px-5 pb-12">
      {/* Header */}
      <div className="pt-10 pb-6 text-center">
        <p className="text-3xl mb-2">{PET_TYPE_LABEL[pet.type] ?? "🐾"}</p>
        <h1 className="text-2xl font-semibold" style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}>
          {pet.name}的星球
        </h1>
        {pet.memorialSentence && (
          <p className="mt-3 text-sm leading-relaxed" style={{ color: "#8a8078" }}>
            {pet.memorialSentence}
          </p>
        )}
      </div>

      {/* Main photo */}
      {mainPhoto && (
        <div className="rounded-2xl overflow-hidden mb-6" style={{ background: "#fff" }}>
          <Image
            src={mainPhoto.r2Url}
            alt={pet.name}
            width={600}
            height={400}
            className="w-full object-cover"
            style={{ maxHeight: 320 }}
          />
        </div>
      )}

      {/* Story */}
      {pet.story && (
        <div
          className="rounded-2xl p-5 mb-6"
          style={{ background: "#fff", border: "1px solid #e8e0d4" }}
        >
          <p className="text-xs mb-2 font-medium" style={{ color: "#7e9366" }}>TA的故事</p>
          <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: "#2c2c2c" }}>
            {pet.story}
          </p>
        </div>
      )}

      {/* Hug */}
      {share.hugEnabled && (
        <div
          className="rounded-2xl p-5 mb-6"
          style={{ background: "#fff", border: "1px solid #e8e0d4" }}
        >
          <p className="text-sm text-center mb-4" style={{ color: "#8a8078" }}>
            给{pet.name}送出一个抱抱，让TA知道你来过
          </p>
          <HugButton slug={slug} />
        </div>
      )}

      {/* Footer */}
      <p className="text-center text-xs mt-8" style={{ color: "#8a8078" }}>
        由星屿纪念创建 · 为每一个离去的小生命留下光
      </p>
    </main>
  );
}
