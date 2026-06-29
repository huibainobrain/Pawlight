"use client";

import { useState, useCallback } from "react";
import Image from "next/image";

interface AlbumPhoto {
  id: string;
  url: string;
  caption?: string | null;
}

const MAX_DISPLAY = 6;

// ── Lightbox ──────────────────────────────────────────────────────────────────

function Lightbox({
  photos,
  index,
  onClose,
  onPrev,
  onNext,
}: {
  photos: AlbumPhoto[];
  index: number;
  onClose: () => void;
  onPrev: () => void;
  onNext: () => void;
}) {
  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center"
      style={{ background: "rgba(0,0,0,0.90)" }}
      onClick={onClose}
    >
      {/* Photo */}
      <div
        className="relative"
        style={{ width: "min(90vw, 420px)", height: "min(90vw, 420px)" }}
        onClick={(e) => e.stopPropagation()}
      >
        <Image
          src={photos[index].url}
          alt={photos[index].caption ?? ""}
          fill
          className="object-contain"
          sizes="90vw"
        />
      </div>

      {/* Prev / Next */}
      {photos.length > 1 && (
        <>
          <button
            aria-label="上一张"
            onClick={(e) => { e.stopPropagation(); onPrev(); }}
            className="absolute left-2 top-1/2 -translate-y-1/2 p-4"
            style={{ color: "rgba(255,255,255,0.65)", fontSize: "30px", lineHeight: 1 }}
          >
            ‹
          </button>
          <button
            aria-label="下一张"
            onClick={(e) => { e.stopPropagation(); onNext(); }}
            className="absolute right-2 top-1/2 -translate-y-1/2 p-4"
            style={{ color: "rgba(255,255,255,0.65)", fontSize: "30px", lineHeight: 1 }}
          >
            ›
          </button>
        </>
      )}

      {/* Count */}
      <p
        className="absolute top-5 left-0 right-0 text-center text-xs"
        style={{ color: "rgba(255,255,255,0.38)" }}
      >
        {index + 1} / {photos.length}
      </p>

      {/* Caption */}
      {photos[index].caption && (
        <p
          className="absolute bottom-8 left-0 right-0 text-center text-sm px-8"
          style={{ color: "rgba(255,255,255,0.62)" }}
        >
          {photos[index].caption}
        </p>
      )}

      {/* Close */}
      <button
        aria-label="关闭"
        onClick={onClose}
        className="absolute top-4 right-4 p-2"
        style={{ color: "rgba(255,255,255,0.55)", fontSize: "26px", lineHeight: 1 }}
      >
        ×
      </button>
    </div>
  );
}

// ── Thumb ─────────────────────────────────────────────────────────────────────

function Thumb({
  photo,
  onClick,
  overlay,
  sizes,
  aspectClass = "aspect-square",
}: {
  photo: AlbumPhoto;
  onClick: () => void;
  overlay?: React.ReactNode;
  sizes: string;
  aspectClass?: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`relative ${aspectClass} w-full rounded-xl overflow-hidden active:opacity-75 transition-opacity`}
      style={{ background: "#ede7de" }}
      aria-label={photo.caption ?? "查看照片"}
    >
      <Image
        src={photo.url}
        alt={photo.caption ?? ""}
        fill
        className="object-cover"
        sizes={sizes}
        loading="lazy"
      />
      {overlay}
    </button>
  );
}

// ── Main export ───────────────────────────────────────────────────────────────

export default function PhotoSection({ photos }: { photos: AlbumPhoto[] }) {
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);

  const display = photos.slice(0, MAX_DISPLAY);
  const hasMore = photos.length > MAX_DISPLAY;
  const moreCount = photos.length - MAX_DISPLAY;

  const open = useCallback((i: number) => setLightboxIndex(i), []);
  const close = useCallback(() => setLightboxIndex(null), []);
  const prev = useCallback(
    () =>
      setLightboxIndex((p) =>
        p === null ? null : (p - 1 + display.length) % display.length
      ),
    [display.length]
  );
  const next = useCallback(
    () =>
      setLightboxIndex((p) =>
        p === null ? null : (p + 1) % display.length
      ),
    [display.length]
  );

  const thumbSizes2col = "calc(50vw - 22px)";
  const thumbSizesFull = "calc(100vw - 32px)";

  // ── 1 photo: full-width, 4:3 ──────────────────────────────────────────────
  if (display.length === 1) {
    return (
      <>
        <Thumb
          photo={display[0]}
          onClick={() => open(0)}
          sizes={thumbSizesFull}
          aspectClass="aspect-[4/3]"
        />
        {lightboxIndex !== null && (
          <Lightbox photos={display} index={lightboxIndex} onClose={close} onPrev={prev} onNext={next} />
        )}
      </>
    );
  }

  // ── 2 photos: two equal columns ──────────────────────────────────────────
  if (display.length === 2) {
    return (
      <>
        <div className="grid grid-cols-2 gap-2">
          {display.map((photo, i) => (
            <Thumb
              key={photo.id}
              photo={photo}
              onClick={() => open(i)}
              sizes={thumbSizes2col}
            />
          ))}
        </div>
        {lightboxIndex !== null && (
          <Lightbox photos={display} index={lightboxIndex} onClose={close} onPrev={prev} onNext={next} />
        )}
      </>
    );
  }

  // ── 3-6 photos: 2-column grid, +N overlay on last slot if truncated ──────
  return (
    <>
      <div className="grid grid-cols-2 gap-2">
        {display.map((photo, i) => {
          const isLastWithMore = hasMore && i === MAX_DISPLAY - 1;
          return (
            <Thumb
              key={photo.id}
              photo={photo}
              onClick={() => open(i)}
              sizes={thumbSizes2col}
              overlay={
                isLastWithMore ? (
                  <div
                    className="absolute inset-0 flex items-center justify-center"
                    style={{ background: "rgba(30,28,25,0.48)" }}
                  >
                    <span
                      style={{
                        color: "#fff",
                        fontSize: "22px",
                        fontWeight: 500,
                        letterSpacing: "0.02em",
                      }}
                    >
                      +{moreCount}
                    </span>
                  </div>
                ) : undefined
              }
            />
          );
        })}
      </div>
      {lightboxIndex !== null && (
        <Lightbox photos={display} index={lightboxIndex} onClose={close} onPrev={prev} onNext={next} />
      )}
    </>
  );
}
