import SwiftUI

// PRD §25: a single "星球来信"/"星球纪事" — same object, different read
// state (PRD §22). Marks itself read on appear (PRD §19: the wait restarts
// once the user has actually read it, not on publish).
struct PlanetEventDetailView: View {
    let event: ApiPlanetEvent

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @State private var showGiftSheet = false
    @State private var showBadCaseConfirm = false
    @State private var isBusy = false

    private var s: Strings { ls.strings }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(s.planetLifeAiBadge)
                    .font(AppFonts.body(11, weight: .medium))
                    .foregroundColor(AppColors.muted.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.muted.opacity(0.08))
                    .cornerRadius(12)

                AsyncImage(url: URL(string: event.imageR2Url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(AppColors.paperSoft)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(event.title)
                    .font(AppFonts.serif(20, weight: .medium))
                    .foregroundColor(AppColors.ink)

                Text(event.body)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink.opacity(0.85))
                    .lineSpacing(5)

                Text(event.createdAt, style: .date)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted.opacity(0.6))

                giftSection
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(AppColors.paper.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(s.planetLifeBadCaseMenuLabel, role: .destructive) {
                        showBadCaseConfirm = true
                    }
                } label: {
                    Text(s.planetLifeWeakMenuLabel)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted.opacity(0.55))
                }
            }
        }
        .task {
            await markReadIfNeeded()
            await loadGiftStatus()
        }
        .alert(s.planetLifeBadCaseConfirmTitle, isPresented: $showBadCaseConfirm) {
            Button(s.planetLifeBadCaseConfirmBtn, role: .destructive) { Task { await performBadCase() } }
            Button(s.cancel, role: .cancel) {}
        } message: {
            Text(s.planetLifeBadCaseConfirmBody)
        }
        .sheet(isPresented: $showGiftSheet) {
            GiftSelectionView()
        }
    }

    @ViewBuilder
    private var giftSection: some View {
        if let pending = planetLife.gifts?.pending, let asset = pending.giftAsset {
            VStack(alignment: .leading, spacing: 8) {
                Text(s.planetLifeGiftPendingStatus(name(for: asset)))
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.ink)
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(s.planetLifeGiftWaitingChip)
                        .font(AppFonts.body(11, weight: .medium))
                }
                .foregroundColor(AppColors.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.gold.opacity(0.12))
                .cornerRadius(8)
            }
            .padding(14)
            .background(AppColors.green.opacity(0.06))
            .cornerRadius(12)
        } else {
            Button {
                showGiftSheet = true
            } label: {
                Text(s.planetLifeGiftCta)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppColors.greenDeep)
                    .cornerRadius(12)
            }
        }
    }

    private func name(for asset: ApiGiftAsset) -> String {
        ls.language == .zh ? asset.nameZh : asset.nameEn
    }

    private func markReadIfNeeded() async {
        guard event.status == .unread,
              let petId = appState.currentPet?.id,
              let token = KeychainHelper.loadToken() else { return }
        _ = await planetLife.markRead(token: token, petId: petId, eventId: event.id)
    }

    private func loadGiftStatus() async {
        guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
        await planetLife.loadGifts(token: token, petId: petId)
    }

    private func performBadCase() async {
        guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
        isBusy = true
        _ = await planetLife.markBadCase(token: token, petId: petId, eventId: event.id)
        isBusy = false
        await planetLife.loadEvents(token: token, petId: petId)
    }
}
