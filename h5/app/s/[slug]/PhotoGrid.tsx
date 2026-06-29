"use client";

import { useState, useCallback } from "react";
import Image from "next/image";

interface AlbumPhoto {
  id: string;
  url: string;
  caption?: string | null;
}

export default function PhotoGrid({ photos }: { photos: AlbumPhoto[] }) {
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);

  const prev = useCallback(() => {
    setLightboxIndex((i) => (i === null ? null : (i - 1 + photos.length) % photos.length));
  }, [photos.length]);

  const next = useCallback(() => {
    setLightboxIndex((i) => (i === null ? null : (i + 1) % photos.length));
  }, [photos.length]);

  return (
    <>
      <div className="grid grid-cols-2 gap-2 px-4">
        {photos.map((photo, i) => (
          <button
            key={photo.id}
            onClick={() => setLightboxIndex(i)}
            className="relative aspect-square rounded-xl overflow-hidden active:opacity-75 transition-opacity"
            style={{ background: "#ede7de" }}
            aria-label={photo.caption ?? "查看照片"}
          >
            <Image
              src={photo.url}
              alt={photo.caption ?? ""}
              fill
              sizes="(max-width: 448px) 48vw, 200px"
              className="object-cover"
            />
          </button>
        ))}
      </div>

      {lightboxIndex !== null && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center"
          style={{ background: "rgba(0,0,0,0.88)" }}
          onClick={() => setLightboxIndex(null)}
        >
          {/* Photo */}
          <div
            className="relative"
            style={{ width: "min(88vw, 420px)", height: "min(88vw, 420px)" }}
            onClick={(e) => e.stopPropagation()}
          >
            <Image
              src={photos[lightboxIndex].url}
              alt={photos[lightboxIndex].caption ?? ""}
              fill
              className="object-contain"
              sizes="88vw"
            />
          </div>

          {/* Caption */}
          {photos[lightboxIndex].caption && (
            <p
              className="absolute bottom-8 left-0 right-0 text-center text-sm px-8"
              style={{ color: "rgba(255,255,255,0.7)" }}
            >
              {photos[lightboxIndex].caption}
            </p>
          )}

          {/* Prev / Next */}
          {photos.length > 1 && (
            <>
              <button
                onClick={(e) => { e.stopPropagation(); prev(); }}
                className="absolute left-3 top-1/2 -translate-y-1/2 p-3"
                style={{ color: "rgba(255,255,255,0.7)", fontSize: "24px", lineHeight: 1 }}
                aria-label="上一张"
              >
                ‹
              </button>
              <button
                onClick={(e) => { e.stopPropagation(); next(); }}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-3"
                style={{ color: "rgba(255,255,255,0.7)", fontSize: "24px", lineHeight: 1 }}
                aria-label="下一张"
              >
                ›
              </button>
            </>
          )}

          {/* Count */}
          <p
            className="absolute top-5 left-0 right-0 text-center text-xs"
            style={{ color: "rgba(255,255,255,0.45)" }}
          >
            {lightboxIndex + 1} / {photos.length}
          </p>

          {/* Close */}
          <button
            onClick={() => setLightboxIndex(null)}
            className="absolute top-4 right-4 p-2"
            style={{ color: "rgba(255,255,255,0.6)", fontSize: "22px", lineHeight: 1 }}
            aria-label="关闭"
          >
            ×
          </button>
        </div>
      )}
    </>
  );
}
