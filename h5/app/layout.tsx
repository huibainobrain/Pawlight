import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pawlight",
  description: "A quiet place to keep their light",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full flex flex-col bg-paper">{children}</body>
    </html>
  );
}
