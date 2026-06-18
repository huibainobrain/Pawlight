import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "星屿纪念",
  description: "在这里，TA的星球永远亮着",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN" className="h-full">
      <body className="min-h-full flex flex-col bg-paper">{children}</body>
    </html>
  );
}
