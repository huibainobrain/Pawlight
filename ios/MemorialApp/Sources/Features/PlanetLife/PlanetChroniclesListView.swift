import SwiftUI

// PRD §39: "回忆 → 星球纪事" — a slowly-growing album, not a feed. The one
// current UNREAD item (if any) appears at the top with a small "来信" chip;
// everything else is a read 星球纪事. Reachable even before the user has
// ever enabled Star Life (PRD §12's long-term entry point).
struct PlanetChroniclesListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @State private var showSettings = false
    @State private var showEnableSheet = false

    private var s: Strings { ls.strings }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(20)
        }
        .background(AppColors.paper.ignoresSafeArea())
        .navigationTitle(s.planetLifeChroniclesNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if planetLife.status?.state?.enabled == true {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task(id: appState.currentPet?.id) {
            guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
            await planetLife.loadStatus(token: token, petId: petId)
            await planetLife.loadEvents(token: token, petId: petId)
        }
        .sheet(isPresented: $showSettings) {
            PlanetLifeSettingsView()
        }
        .sheet(isPresented: $showEnableSheet) {
            PlanetLifeEnableSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        if planetLife.events.isEmpty {
            emptyState
        } else {
            VStack(spacing: 14) {
                // Production asset: decorative header illustration (pet +
                // doghouse scene in the reference UI) — placeholder slot only.
                PlanetLifeIllustrationSlot(
                    assetName: "planet_life_chronicles_header",
                    systemImageFallback: "moon.stars.fill",
                    size: 88
                )
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)

                LazyVStack(spacing: 14) {
                    ForEach(planetLife.events) { event in
                        NavigationLink {
                            PlanetEventDetailView(event: event)
                        } label: {
                            ChronicleRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if planetLife.status?.state?.enabled != true {
            // Never enabled yet — offer the long-term entry point (PRD §12).
            VStack(spacing: 14) {
                // Production asset: decorative hero illustration (the same
                // "planet in a glass dome" motif as the home observation
                // window, reused here for the not-yet-enabled empty state
                // per the reference UI) — placeholder slot only.
                PlanetLifeIllustrationSlot(
                    assetName: "planet_life_hero_empty",
                    systemImageFallback: "sparkles",
                    size: 110
                )
                Text(s.planetLifeIntroTitle)
                    .font(AppFonts.serif(17, weight: .medium))
                    .foregroundColor(AppColors.ink)
                    .multilineTextAlignment(.center)
                Text(s.planetLifeIntroBody)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
                Button {
                    showEnableSheet = true
                } label: {
                    Text(s.planetLifeIntroEnableBtn)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(AppColors.greenDeep)
                        .cornerRadius(20)
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            VStack(spacing: 10) {
                PlanetLifeIllustrationSlot(
                    assetName: "planet_life_hero_empty",
                    systemImageFallback: "moon.stars.fill",
                    size: 88
                )
                Text(s.planetLifeChroniclesEmptyTitle)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.ink)
                    .multilineTextAlignment(.center)
                Text(s.planetLifeChroniclesEmptyBody)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        }
    }
}

private struct ChronicleRow: View {
    let event: ApiPlanetEvent
    @EnvironmentObject var ls: LanguageStore
    private var s: Strings { ls.strings }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: event.imageR2Url)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: Rectangle().fill(AppColors.paperSoft)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if event.status == .unread {
                        Text(s.planetLifeUnreadChip)
                            .font(AppFonts.body(10, weight: .medium))
                            .foregroundColor(AppColors.greenDeep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AppColors.green.opacity(0.14))
                            .cornerRadius(8)
                    }
                    Text(event.title)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .lineLimit(1)
                }
                Text(event.createdAt, style: .date)
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.muted.opacity(0.6))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.muted.opacity(0.35))
        }
        .padding(12)
        .background(AppColors.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}
