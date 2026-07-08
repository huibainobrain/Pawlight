import SwiftUI

struct MailboxView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss

    private var s: Strings { ls.strings }

    @State private var selectedLetter: Letter? = nil
    @State private var showLetterDetail = false
    @State private var showLetterEdit = false
    @State private var isLoading = false
    @State private var loadError = false

    private let warmBrown = Color(red: 0.37, green: 0.29, blue: 0.15)

    var body: some View {
        Group {
            if isLoading || loadError || !appState.letters.isEmpty {
                populatedStateContent
            } else {
                emptyStateScreen
            }
        }
        .navigationTitle(s.mailboxNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .padding(9)
                        .background(.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 1)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(s.mailboxNavTitle)
                    .font(AppFonts.serif(17, weight: .medium))
                    .foregroundStyle(AppColors.ink)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showLetterEdit = true } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .padding(9)
                        .background(.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 1)
                }
            }
        }
        .navigationDestination(isPresented: $showLetterDetail) {
            if let letter = selectedLetter {
                LetterDetailView(letter: letter, isPresented: $showLetterDetail)
            }
        }
        .navigationDestination(isPresented: $showLetterEdit) {
            LetterEditView(existingLetter: nil, isPresented: $showLetterEdit)
        }
        .task { await loadLetters() }
    }

    // MARK: - Populated / loading / error state (unchanged hero layout)

    @ViewBuilder private var populatedStateContent: some View {
        ZStack {
            Image("mailbox_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                privacyHintView
                heroView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.muted)
                                .padding(.vertical, 44)
                        } else if loadError && appState.letters.isEmpty {
                            errorStateView.padding(.top, 24)
                        } else {
                            letterListContent
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(Color(red: 0.987, green: 0.980, blue: 0.968))

                pinnedFooterView
            }
        }
    }

    // MARK: - Privacy hint

    private var privacyHintView: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
                .foregroundStyle(AppColors.muted.opacity(0.42))
            Text(s.mailboxPrivacyHint)
                .font(AppFonts.body(12))
                .foregroundStyle(AppColors.muted.opacity(0.42))
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Hero

    private var heroView: some View {
        // HStack fixed to 190pt tall and clipped — the envelope image renders at its
        // natural scaledToFit height (~312pt) and gets clipped by the HStack boundary.
        // This eliminates the need to clip the image separately and avoids any residual
        // frame artifacts. alignment: .top anchors both children to the top edge.
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(s.mailboxHeroTitle)
                    .font(AppFonts.serif(21, weight: .medium))
                    .foregroundStyle(warmBrown)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Text(s.mailboxHeroBody)
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.muted.opacity(0.68))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 20)
            .padding(.top, 26)
            .padding(.bottom, 18)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Warm fill suppresses the circular botanical decoration in mailbox_bg
            // that coincides with the title text position. Higher opacity (0.88) to
            // ensure the decoration is fully masked.
            .background(
                Color(red: 0.966, green: 0.955, blue: 0.934).opacity(0.88)
                    .blur(radius: 8)
                    .padding(.horizontal, -14)
                    .padding(.vertical, -6)
            )

            // Envelope visual. scaledToFill at explicit 148×190pt, alignment: .top shows
            // the upper portion of the asset where the envelope + botanicals sit.
            // scaledToFit was wrong — at 148pt wide with 190pt height proposal it scaled
            // to fit HEIGHT (producing a 90pt-wide image). scaledToFill fills the width.
            // Left-edge gradient mask dissolves the seam between envelope and text column.
            Image("mailbox_hero_envelope")
                .resizable()
                .scaledToFill()
                .frame(width: 148, height: 190, alignment: .top)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.22),
                            .init(color: .black, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 204)
        .clipped()
    }

    // MARK: - Letter list content

    @ViewBuilder private var letterListContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "envelope")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.muted.opacity(0.5))
                Text(s.mailboxLetterCount(appState.letters.count))
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.muted.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            VStack(spacing: 14) {
                ForEach(appState.letters) { letter in
                    LetterCardView(letter: letter)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLetter = letter
                            showLetterDetail = true
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Empty state (no letters yet)
    // Standalone lightweight screen — intentionally does not reuse privacyHintView /
    // heroView / mailbox_bg from the populated state, so only one envelope visual
    // (letter_empty_state) appears instead of two stacked ones.

    @ViewBuilder private var emptyStateScreen: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    emptyPrivacyHintView
                        .padding(.top, 20)

                    Spacer(minLength: 56)

                    Image("letter_empty_state")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(max(geo.size.width * 0.5, 180), 230))

                    Spacer(minLength: 32)

                    VStack(spacing: 10) {
                        Text(s.mailboxEmptyTitle)
                            .font(AppFonts.serif(18, weight: .medium))
                            .foregroundStyle(AppColors.ink)
                        Text(s.mailboxEmptyBody)
                            .font(AppFonts.body(13))
                            .foregroundStyle(AppColors.muted.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 40)
                    }

                    Spacer(minLength: 32)

                    Button { showLetterEdit = true } label: {
                        Text(s.mailboxWriteFirstBtn)
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundStyle(AppColors.white)
                            .frame(width: 240, height: 54)
                            .background(AppColors.greenDeep.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: AppColors.greenDeep.opacity(0.12), radius: 8, x: 0, y: 3)
                    }

                    Spacer()

                    emptyFooterView
                        .padding(.bottom, 28)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
        .background(
            Color(red: 0.987, green: 0.980, blue: 0.968)
                .ignoresSafeArea()
        )
    }

    private var emptyPrivacyHintView: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
                .foregroundStyle(AppColors.muted.opacity(0.42))
            Text(s.mailboxPrivacyHint)
                .font(AppFonts.body(12))
                .foregroundStyle(AppColors.muted.opacity(0.42))
        }
    }

    private var emptyFooterView: some View {
        VStack(spacing: 7) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.green.opacity(0.28))
            Text(s.mailboxFooter)
                .font(AppFonts.body(11))
                .foregroundStyle(AppColors.muted.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Error state

    @ViewBuilder private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.muted.opacity(0.32))
            VStack(spacing: 6) {
                Text(s.mailboxLoadError)
                    .font(AppFonts.body(15))
                    .foregroundStyle(AppColors.muted)
                Text(s.mailboxLoadErrorBody)
                    .font(AppFonts.body(13))
                    .foregroundStyle(AppColors.muted.opacity(0.7))
            }
            Button(s.reload) {
                loadError = false
                Task { await loadLetters() }
            }
            .font(AppFonts.body(14))
            .foregroundStyle(AppColors.greenDeep)
        }
        .padding(.top, 44)
        .padding(.bottom, 32)
    }

    // MARK: - Pinned footer

    private var pinnedFooterView: some View {
        VStack(spacing: 7) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.green.opacity(0.28))
            Text(s.mailboxFooter)
                .font(AppFonts.body(12))
                .foregroundStyle(AppColors.muted.opacity(0.42))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 14)
        .padding(.bottom, 44)
        .frame(maxWidth: .infinity)
        // Solid cream — matches ScrollView background above for a continuous panel.
        // ignoresSafeArea fills the home-indicator zone so no botanical shows below.
        // Bottom 44pt: home indicator is ~34pt from screen bottom when VStack fills
        // full screen height, so 44pt keeps text 10pt above the indicator.
        .background(
            Color(red: 0.987, green: 0.980, blue: 0.968)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Data

    private func loadLetters() async {
        guard let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        if appState.letters.isEmpty { isLoading = true }
        do {
            let apiLetters = try await APIClient.shared.fetchLetters(token: token, petId: petId)
            appState.letters = apiLetters.map { l in
                Letter(id: l.id, petId: l.petId, userId: appState.currentUser?.id ?? "",
                       title: l.title, content: l.content,
                       createdAt: l.createdAt, updatedAt: l.updatedAt)
            }
            loadError = false
        } catch {
            if appState.letters.isEmpty { loadError = true }
        }
        isLoading = false
    }
}

// MARK: - Letter card

struct LetterCardView: View {
    let letter: Letter
    @EnvironmentObject var ls: LanguageStore

    private var displayTitle: String {
        if let t = letter.title, !t.trimmingCharacters(in: .whitespaces).isEmpty { return t }
        return ls.strings.mailboxDefaultTitle
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 7) {
                    Circle()
                        .fill(Color(red: 0.47, green: 0.60, blue: 0.37))
                        .frame(width: 6, height: 6)
                    Text(displayTitle)
                        .font(AppFonts.body(16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.23, green: 0.18, blue: 0.09))
                        .lineLimit(1)
                }

                Text(letter.content)
                    .font(AppFonts.body(13))
                    .foregroundStyle(AppColors.muted.opacity(0.7))
                    .lineLimit(2)
                    .lineSpacing(3)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.muted.opacity(0.42))
                    Text(ls.strings.letterWrittenOn(letter.createdAt))
                        .font(AppFonts.body(11))
                        .foregroundStyle(AppColors.muted.opacity(0.42))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.muted.opacity(0.38))
                .padding(.top, 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 108)
        .background {
            Image("mailbox_card_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .shadow(color: .black.opacity(0.045), radius: 7, x: 0, y: 2)
    }
}
