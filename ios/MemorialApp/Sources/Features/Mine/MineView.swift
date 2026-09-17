import SwiftUI

struct MineView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var showDeleteAlert = false
    @State private var isDeletingAccount = false
    @State private var showDeleteError = false
    @State private var showOnboarding = false
    @State private var goPetProfile = false
    @State private var goEntitlement = false
    @State private var goPrivacySettings = false
    @Environment(\.openURL) var openURL

    // 临时隐藏「开发调试」模块；需要恢复时改回 true 即可
    private let showDevDebugSection = false

    private var s: Strings { ls.strings }
    private let privacyURL = URL(string: "https://pet-memory-psi.vercel.app/privacy")!
    private let feedbackEmail = URL(string: "mailto:ntuwangyiming@gmail.com?subject=Pawlight%20Feedback")!

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                if !appState.hasPet {
                    MineUnboardedView(showOnboarding: $showOnboarding)
                }
                if appState.hasPet {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {

                            HStack {
                                Text(s.mineTitle)
                                    .font(AppFonts.serif(28, weight: .medium))
                                    .foregroundStyle(AppColors.ink)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 20)

                            // 用户账号卡
                            MineAccountCard()
                                .padding(.horizontal, 20)

                            MineSectionLabel(s.minePetSection)
                            MineSectionCard {
                                Button { goPetProfile = true } label: {
                                    MineRowContent(
                                        icon: "pawprint.fill",
                                        iconBg: AppColors.green.opacity(0.12),
                                        iconColor: AppColors.green,
                                        label: appState.currentPet?.name ?? "",
                                        showDivider: true
                                    )
                                }
                                .buttonStyle(.plain)

                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.muted.opacity(0.07))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "plus")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppColors.muted.opacity(0.36))
                                    }
                                    Text(s.mineAddPet)
                                        .font(AppFonts.body(15))
                                        .foregroundStyle(AppColors.muted.opacity(0.48))
                                    Spacer()
                                    Text(s.mineAddPetSoon)
                                        .font(AppFonts.body(11))
                                        .foregroundStyle(AppColors.muted.opacity(0.40))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppColors.muted.opacity(0.07))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                            }
                            .padding(.horizontal, 20)

                            MineSectionLabel(s.mineEntitlementSection)
                            MineSectionCard {
                                Button { goEntitlement = true } label: {
                                    MineRowContent(
                                        icon: appState.isPaid ? "star.fill" : "star",
                                        iconBg: AppColors.gold.opacity(0.12),
                                        iconColor: AppColors.gold,
                                        label: appState.isPaid ? s.minePaidLabel : s.mineFreeLabel,
                                        showDivider: true
                                    )
                                }
                                .buttonStyle(.plain)

                                Button { goPrivacySettings = true } label: {
                                    MineRowContent(
                                        icon: "lock.fill",
                                        iconBg: AppColors.muted.opacity(0.09),
                                        iconColor: AppColors.muted,
                                        label: s.minePrivacyLabel,
                                        showDivider: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)

                            // 开发调试（仅 DEBUG 编译时可见，且受 showDevDebugSection 开关控制）
                            #if DEBUG
                            if showDevDebugSection {
                            MineSectionLabel("开发调试", isDebug: true)
                            MineSectionCard(debugStyle: true) {
                                Button {
                                    appState.entitlement = Entitlement(
                                        entitlementType: .paid, photoLimit: 50,
                                        mailboxEnabled: true, purchaseStatus: .paid)
                                    appState.ownerStage = .hasPetPaid
                                } label: {
                                    MineRowContent(
                                        icon: "star.fill",
                                        iconBg: AppColors.gold.opacity(0.10),
                                        iconColor: AppColors.gold.opacity(0.68),
                                        label: "切换：完整纪念空间（付费）",
                                        showDivider: true
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    appState.entitlement = Entitlement(
                                        entitlementType: .free, photoLimit: 9,
                                        mailboxEnabled: false, purchaseStatus: .none)
                                    appState.ownerStage = .hasPetFree
                                } label: {
                                    MineRowContent(
                                        icon: "star",
                                        iconBg: AppColors.muted.opacity(0.08),
                                        iconColor: AppColors.muted.opacity(0.52),
                                        label: "切换：免费纪念空间",
                                        showDivider: true
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    let fakeHug = Hug(
                                        id: "debug_hug_\(Date().timeIntervalSince1970)",
                                        petId: appState.currentPet?.id ?? "pet_debug",
                                        shareId: "share_debug",
                                        visitorName: ["小明", "旧友", "陌生人", "TA的朋友"].randomElement(),
                                        source: "share",
                                        createdAt: Date()
                                    )
                                    appState.hugs.insert(fakeHug, at: 0)
                                    appState.newHugCount += 1
                                } label: {
                                    MineRowContent(
                                        icon: "heart.fill",
                                        iconBg: AppColors.rose.opacity(0.10),
                                        iconColor: AppColors.rose.opacity(0.68),
                                        label: "模拟收到新抱抱",
                                        showDivider: true
                                    )
                                }
                                .buttonStyle(.plain)

                                Button { appState.resetAll() } label: {
                                    MineRowContent(
                                        icon: "arrow.counterclockwise",
                                        iconBg: AppColors.rose.opacity(0.10),
                                        iconColor: AppColors.rose,
                                        label: "重置（回到注册流程）",
                                        labelColor: AppColors.rose,
                                        showDivider: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            }
                            #endif

                            MineSectionLabel(s.mineSupportSection)
                            MineSectionCard {
                                // Language toggle
                                VStack(spacing: 0) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppColors.green.opacity(0.10))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "globe")
                                                .font(.system(size: 13))
                                                .foregroundStyle(AppColors.green.opacity(0.65))
                                        }
                                        Text(s.mineLanguageSection)
                                            .font(AppFonts.body(15))
                                            .foregroundStyle(AppColors.ink)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            ForEach([AppLanguage.en, AppLanguage.zh], id: \.rawValue) { lang in
                                                Button {
                                                    ls.set(lang)
                                                } label: {
                                                    Text(lang.label)
                                                        .font(AppFonts.body(12, weight: ls.language == lang ? .medium : .regular))
                                                        .foregroundStyle(ls.language == lang ? AppColors.white : AppColors.muted)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(ls.language == lang ? AppColors.greenDeep : AppColors.muted.opacity(0.09))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 13)
                                    Rectangle()
                                        .fill(AppColors.line)
                                        .frame(height: 0.5)
                                        .padding(.leading, 58)
                                }

                                Button { openURL(feedbackEmail) } label: {
                                    MineRowContent(icon: "questionmark.circle.fill", iconBg: AppColors.green.opacity(0.10), iconColor: AppColors.green.opacity(0.65), label: s.mineFeedbackLabel, showDivider: true)
                                }
                                .buttonStyle(.plain)

                                Button { openURL(privacyURL) } label: {
                                    MineRowContent(icon: "doc.text.fill", iconBg: AppColors.green.opacity(0.10), iconColor: AppColors.green.opacity(0.65), label: s.mineTermsLabel, showDivider: true)
                                }
                                .buttonStyle(.plain)

                                Button { openURL(privacyURL) } label: {
                                    MineRowContent(icon: "hand.raised.fill", iconBg: AppColors.green.opacity(0.10), iconColor: AppColors.green.opacity(0.65), label: s.minePrivacyPolicyLabel, showDivider: true)
                                }
                                .buttonStyle(.plain)

                                Button { showDeleteAlert = true } label: {
                                    if isDeletingAccount {
                                        HStack {
                                            ProgressView().tint(AppColors.rose).scaleEffect(0.8)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 13)
                                    } else {
                                        MineRowContent(
                                            icon: "trash.fill",
                                            iconBg: AppColors.rose.opacity(0.10),
                                            iconColor: AppColors.rose,
                                            label: s.mineDeleteAccountLabel,
                                            labelColor: AppColors.rose,
                                            showDivider: false
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isDeletingAccount)
                            }
                            .padding(.horizontal, 20)

                            // 底部氛围区
                            MineBottomDecoration()

                            Spacer(minLength: 80)
                        }
                        .navigationDestination(isPresented: $goPetProfile) { PetProfileView() }
                        .navigationDestination(isPresented: $goEntitlement) { EntitlementView() }
                        .navigationDestination(isPresented: $goPrivacySettings) { PrivacySettingsView() }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(s.mineDeleteAlertTitle, isPresented: $showDeleteAlert) {
                Button(s.mineDeleteConfirmBtn, role: .destructive) { performDeleteAccount() }
                Button(s.cancel, role: .cancel) {}
            } message: {
                Text(s.mineDeleteAlertBody)
            }
            .alert(s.mineDeleteErrorTitle, isPresented: $showDeleteError) {
                Button(s.ok, role: .cancel) {}
            } message: {
                Text(s.mineDeleteErrorBody)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingStartView() }
        .onChange(of: appState.hasPet) { _, hasPet in
            if hasPet { showOnboarding = false }
        }
        .onChange(of: goPetProfile)      { _, _ in syncTabBar() }
        .onChange(of: goEntitlement)     { _, _ in syncTabBar() }
        .onChange(of: goPrivacySettings) { _, _ in syncTabBar() }
    }

    private func syncTabBar() {
        appState.tabBarHidden = goPetProfile || goEntitlement || goPrivacySettings
    }

    private func performDeleteAccount() {
        isDeletingAccount = true
        Task { @MainActor in
            do {
                try await appState.deleteAccount()
            } catch {
                print("deleteAccount error: \(error)")
                isDeletingAccount = false
                showDeleteError = true
            }
        }
    }
}

// MARK: - 未入驻空态

struct MineUnboardedView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.green.opacity(0.10))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(AppColors.green.opacity(0.42))
                }
                VStack(spacing: 10) {
                    Text(s.mineUnboardedTitle)
                        .font(AppFonts.serif(20, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                    Text(s.mineUnboardedBody)
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            Spacer()
            Button {
                showOnboarding = true
            } label: {
                Text(s.createKeepsake)
                    .font(AppFonts.body(16, weight: .medium))
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.greenDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - 用户账号卡

private struct MineAccountCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.green.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.green.opacity(0.68))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.nickname ?? "Apple User")
                    .font(AppFonts.body(16, weight: .medium))
                    .foregroundStyle(AppColors.ink)
                Text(ls.strings.mineAppleLogin)
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.muted.opacity(0.35))
        }
        .padding(16)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.line, lineWidth: 1))
    }
}

// MARK: - Section 标题

private struct MineSectionLabel: View {
    let title: String
    var isDebug: Bool

    init(_ title: String, isDebug: Bool = false) {
        self.title = title
        self.isDebug = isDebug
    }

    var body: some View {
        HStack(spacing: 5) {
            if isDebug {
                Image(systemName: "wrench.adjustable.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.muted.opacity(0.36))
            }
            Text(title)
                .font(AppFonts.body(12))
                .foregroundStyle(isDebug ? AppColors.muted.opacity(0.40) : AppColors.muted.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Section 卡片容器

private struct MineSectionCard<Content: View>: View {
    var debugStyle: Bool
    let content: Content

    init(debugStyle: Bool = false, @ViewBuilder content: () -> Content) {
        self.debugStyle = debugStyle
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(debugStyle ? AppColors.paperSoft : AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.line, lineWidth: 1))
    }
}

// MARK: - 行视图

private struct MineRowContent: View {
    let icon: String
    let iconBg: Color
    let iconColor: Color
    let label: String
    var labelColor: Color = AppColors.ink
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBg)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(iconColor)
                }
                Text(label)
                    .font(AppFonts.body(15))
                    .foregroundStyle(labelColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.muted.opacity(0.38))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())

            if showDivider {
                Rectangle()
                    .fill(AppColors.line)
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

// MARK: - 底部氛围区

private struct MineBottomDecoration: View {
    @EnvironmentObject var ls: LanguageStore

    private var versionText: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return ls.strings.mineVersion(v)
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.green.opacity(0.22))
                    .rotationEffect(.degrees(-30))
                    .offset(x: -38, y: 8)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.green.opacity(0.16))
                    .rotationEffect(.degrees(40))
                    .offset(x: 40, y: 10)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .ultraLight))
                    .foregroundStyle(AppColors.muted.opacity(0.20))
                    .offset(x: -24, y: -22)
                Image(systemName: "hare.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColors.muted.opacity(0.13))
            }
            .frame(height: 72)

            VStack(spacing: 5) {
                Text(ls.strings.mineBottomLine1)
                    .font(AppFonts.body(13))
                    .foregroundStyle(AppColors.muted.opacity(0.46))
                Text(ls.strings.mineBottomLine2)
                    .font(AppFonts.body(13))
                    .foregroundStyle(AppColors.muted.opacity(0.46))
            }

            Text(versionText)
                .font(AppFonts.body(11))
                .foregroundStyle(AppColors.muted.opacity(0.28))
        }
        .padding(.top, 36)
        .padding(.bottom, 16)
    }
}
