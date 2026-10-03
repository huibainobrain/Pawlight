import SwiftUI

// Slots into HomeCreatedView right below the observation window (PRD §23:
// "在首页观察窗附近显示"). Shows at most one of: the unread-letter teaser, or
// the one-time intro card — never both, and nothing once the user has either
// enabled Star Life or dismissed the intro.
struct PlanetLifeHomeSection: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @State private var showEnableSheet = false
    @State private var showEventDetail = false

    private var s: Strings { ls.strings }

    var body: some View {
        Group {
            if let unread = planetLife.status?.unread {
                PlanetLifeUnreadIndicator(event: unread) { showEventDetail = true }
                    .navigationDestination(isPresented: $showEventDetail) {
                        PlanetEventDetailView(event: unread)
                    }
            } else if shouldShowIntro {
                PlanetLifeIntroCard(
                    onEnable: { showEnableSheet = true },
                    onLater: { planetLife.markIntroSeen() }
                )
            }
        }
        .task(id: appState.currentPet?.id) {
            guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
            await planetLife.loadStatus(token: token, petId: petId)
        }
        .sheet(isPresented: $showEnableSheet) {
            PlanetLifeEnableSheet()
        }
    }

    // PRD §11: offer only after the first completed AI scene; PRD §12: once
    // dismissed with "稍后", never re-prompt (hasSeenIntro is local/device-
    // level, independent of server state).
    private var shouldShowIntro: Bool {
        appState.currentPet?.observationVideoUrl != nil
            && planetLife.status?.state?.enabled != true
            && !planetLife.hasSeenIntro
    }
}

// MARK: - Intro card (PRD §11)

private struct PlanetLifeIntroCard: View {
    @EnvironmentObject var ls: LanguageStore
    let onEnable: () -> Void
    let onLater: () -> Void

    private var s: Strings { ls.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.green.opacity(0.6))
                    Text(s.planetLifeIntroTitle)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(AppColors.ink)
                }
                Text(s.planetLifeIntroBody)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
                    .lineSpacing(3)
                HStack(spacing: 10) {
                    Button(action: onEnable) {
                        Text(s.planetLifeIntroEnableBtn)
                            .font(AppFonts.body(13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(AppColors.greenDeep)
                            .cornerRadius(20)
                    }
                    Button(action: onLater) {
                        Text(s.planetLifeIntroLaterBtn)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
            // Production asset: a decorative polaroid-photo-stack
            // illustration (see reference UI) — placeholder slot only.
            PlanetLifeIllustrationSlot(
                assetName: "planet_life_intro_photos",
                systemImageFallback: "photo.stack",
                size: 56
            )
        }
        .padding(16)
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}

// MARK: - Unread indicator (PRD §23 — explicitly no red dot / unread count)
//
// PRD §23's exact example is 3 lines: "✦ 星球来了一封新信 / 风吹过草地的时候 /
// 查看 →" — the second line is the event's own title (confirmed against the
// reference: that exact phrase is literally the chronicle's title in the
// companion reference image), not fixed copy. Showing only line 1 (as this
// view did before this round's audit) silently dropped that second line.

private struct PlanetLifeUnreadIndicator: View {
    let event: ApiPlanetEvent
    let onView: () -> Void
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        Button(action: onView) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.planetLifeNewLetterBadge)
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text(event.title)
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted)
                        .lineLimit(1)
                    Text(s.planetLifeViewBtn)
                        .font(AppFonts.body(12, weight: .medium))
                        .foregroundColor(AppColors.greenDeep)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
                // Production asset: decorative envelope illustration (see
                // reference UI) — placeholder slot only.
                PlanetLifeIllustrationSlot(
                    assetName: "planet_life_envelope",
                    systemImageFallback: "envelope.fill",
                    size: 44
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.green.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.green.opacity(0.18), lineWidth: 1)
            )
        }
    }
}
