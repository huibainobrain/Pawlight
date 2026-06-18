import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "pub-e338812aab07453fb6daedf09626d543.r2.dev",
      },
    ],
  },
};

export default nextConfig;
