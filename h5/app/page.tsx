export const dynamic = "force-dynamic";

export default function Home() {
  return (
    <main className="flex flex-col items-center justify-center min-h-screen px-5 text-center">
      <p className="text-4xl mb-4">🌙</p>
      <h1
        className="text-2xl font-semibold mb-2"
        style={{ fontFamily: "Georgia, serif", color: "#2c2c2c" }}
      >
        星屿纪念
      </h1>
      <p className="text-sm" style={{ color: "#8a8078" }}>
        为每一个离去的小生命，留下一颗永恒的星球
      </p>
    </main>
  );
}
