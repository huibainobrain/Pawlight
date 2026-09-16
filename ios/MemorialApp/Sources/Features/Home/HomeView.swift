import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                if appState.hasPet {
                    HomeCreatedView()
                } else {
                    HomeUnboardedView(showOnboarding: $showOnboarding)
                }
            }
            .scenePortraitOverlay()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingStartView()
        }
        .onChange(of: appState.hasPet) { _, hasPet in
            if hasPet { showOnboarding = false }
        }
    }
}

// MARK: - 未入驻

struct HomeUnboardedView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var ls: LanguageStore
    @State private var showLearnMore = false

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.green.opacity(0.18), AppColors.blue.opacity(0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 200, height: 200)
                    Circle()
                        .fill(AppColors.paperSoft)
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.green.opacity(0.5))
                }
                VStack(spacing: 12) {
                    Text(s.homeUnboardedTitle)
                        .font(AppFonts.serif(22, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                    Text(s.homeUnboardedBody)
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
            }
            Spacer()
            VStack(spacing: 14) {
                Button {
                    showOnboarding = true
                } label: {
                    Text(s.createKeepsake)
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.greenDeep)
                        .cornerRadius(12)
                }
                Button(s.learnMore) { showLearnMore = true }
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showLearnMore) { LearnMoreSheet() }
    }
}

// MARK: - 了解一下

struct LearnMoreSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(s.learnMoreTitle)
                    .font(AppFonts.serif(18, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.muted)
                        .padding(8)
                        .background(AppColors.line)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 24) {
                LearnMoreItem(icon: "moon.stars.fill", title: s.learnMoreItem1Title,
                              detail: s.learnMoreItem1Detail)
                LearnMoreItem(icon: "photo.on.rectangle", title: s.learnMoreItem2Title,
                              detail: s.learnMoreItem2Detail)
                LearnMoreItem(icon: "heart.fill", title: s.learnMoreItem3Title,
                              detail: s.learnMoreItem3Detail)
            }
            .padding(.horizontal, 24)
            Spacer()
            Button { dismiss() } label: {
                Text(s.learnMoreOk)
                    .font(AppFonts.body(15, weight: .medium))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.greenDeep)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.paper.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}

struct LearnMoreItem: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.green)
                .frame(width: 22, height: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body(15, weight: .medium))
                    .foregroundColor(AppColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 已入驻

struct HomeCreatedView: View {
    @EnvironmentObject var appState: AppState
    @State private var showHugs = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                PlanetWindowView()
                    .padding(.top, 12)

                if appState.newHugCount > 0 {
                    HugReminderCard(newCount: appState.newHugCount)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.markHugsSeen()
                            showHugs = true
                        }
                }

                QuickActionsRow()
                    .padding(.horizontal, 20)

                MemoryStatusCard()
                    .padding(.horizontal, 20)

                if appState.entitlement?.isFree == true {
                    FreeUpgradeCard()
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
        .navigationDestination(isPresented: $showHugs) {
            HugsView()
        }
    }
}

// MARK: - 星球观察窗

struct PlanetWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var scenePortrait: ScenePortraitController

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 18) {
            // 观察窗主体
            ZStack {
                // 外层光晕
                Circle()
                    .fill(AppColors.green.opacity(0.04))
                    .frame(width: 296, height: 296)
                Circle()
                    .fill(AppColors.green.opacity(0.06))
                    .frame(width: 264, height: 264)

                // 轻轨道环
                Ellipse()
                    .stroke(AppColors.muted.opacity(0.16), lineWidth: 1.0)
                    .frame(width: 278, height: 62)
                    .rotationEffect(.degrees(-16))

                // 温暖金色星光散点
                Group {
                    HomeSparkle(size: 12).offset(x: -100, y: -82)
                    HomeSparkle(size: 9).offset(x: 86, y: -108)
                    HomeSparkle(size: 11).offset(x: -118, y: 26)
                    HomeSparkle(size: 8).offset(x: 128, y: 54)
                    HomeSparkle(size: 7).offset(x: -58, y: -118)
                    HomeSparkle(size: 6).offset(x: 56, y: -92)
                }

                // 星点小点
                Group {
                    Circle().fill(HomeStarColor.opacity(0.42)).frame(width: 4).offset(x: -136, y: -38)
                    Circle().fill(HomeStarColor.opacity(0.30)).frame(width: 3).offset(x: 108, y: -46)
                    Circle().fill(HomeStarColor.opacity(0.38)).frame(width: 3.5).offset(x: -78, y: 102)
                    Circle().fill(HomeStarColor.opacity(0.25)).frame(width: 2.5).offset(x: 140, y: -20)
                }

                // 新月（右上角）
                ZStack {
                    Circle()
                        .fill(Color(red: 0.91, green: 0.87, blue: 0.79))
                        .frame(width: 36, height: 36)
                    Circle()
                        .fill(AppColors.paper)
                        .frame(width: 28, height: 28)
                        .offset(x: 9, y: -8)
                }
                .offset(x: 118, y: -94)

                // 轨道小卫星点
                Circle()
                    .fill(AppColors.muted.opacity(0.22))
                    .frame(width: 8, height: 8)
                    .offset(x: 136, y: 22)

                // 绿色装饰环 + 主照片（仅照片圆圈可点击，避免整区域误触）
                ZStack {
                    // 外装饰环
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.green.opacity(0.34),
                                    AppColors.green.opacity(0.22),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 224, height: 224)

                    // 内白圈（环宽效果）
                    Circle()
                        .fill(AppColors.paper)
                        .frame(width: 210, height: 210)

                    // 用户上传主照片
                    if appState.isPaid,
                       scenePortrait.stage.isActive || appState.currentPet?.observationVideoUrl != nil {
                        ScenePortraitObservationContent(
                            stage: scenePortrait.stage,
                            videoUrl: appState.currentPet?.observationVideoUrl
                        )
                        .frame(width: 206, height: 206)
                        .clipShape(Circle())
                    } else if let photo = appState.currentPet?.mainPhoto {
                        AsyncImage(url: URL(string: photo.url)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 54))
                                    .foregroundColor(AppColors.green.opacity(0.35))
                            }
                        }
                        .frame(width: 206, height: 206)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.paperSoft)
                            .frame(width: 206, height: 206)
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 54))
                            .foregroundColor(AppColors.green.opacity(0.35))
                    }
                }
                .contentShape(Circle())
                .onTapGesture { appState.selectedTab = 1 }
            }
            .frame(width: 310, height: 280)

            // 宠物名 + 纪念语
            VStack(spacing: 8) {
                // 名字 + 小叶片装饰
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.green.opacity(0.38))
                    Text(appState.currentPet?.name ?? "")
                        .font(AppFonts.serif(24, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.green.opacity(0.38))
                        .scaleEffect(x: -1, y: 1)
                }

                if scenePortrait.stage.isGenerating {
                    Text(scenePortrait.stage == .generatingImage
                         ? s.scenePortraitGeneratingImage
                         : s.scenePortraitGeneratingVideo)
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                } else if let sentence = appState.currentPet?.memorialSentence, !sentence.isEmpty {
                    Text(sentence)
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text(s.homeSentencePlaceholder)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted.opacity(0.46))
                }

                if appState.isPaid, appState.currentPet?.mainPhoto != nil,
                   scenePortrait.stage == .idle {
                    if appState.currentPet?.observationVideoUrl != nil {
                        ScenePortraitRevertButton()
                    } else {
                        ScenePortraitEntryButton()
                    }
                }
            }
        }
    }
}

// 暖金色4角星光
private struct HomeSparkle: View {
    let size: CGFloat
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .ultraLight))
            .foregroundColor(HomeStarColor.opacity(0.55))
    }
}

private let HomeStarColor = Color(red: 0.80, green: 0.72, blue: 0.54)

// MARK: - 抱抱提醒卡

struct HugReminderCard: View {
    let newCount: Int
    @EnvironmentObject var ls: LanguageStore

    private var hasNew: Bool { newCount > 0 }
    private var s: Strings { ls.strings }

    var body: some View {
        HStack(spacing: 14) {
            // 信封插画图标
            ZStack {
                Circle()
                    .fill(AppColors.green.opacity(0.10))
                    .frame(width: 48, height: 48)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.green.opacity(0.58))
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.rose.opacity(0.62))
                    .offset(x: 8, y: -7)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(hasNew ? s.hugReminderHasNewTitle : s.hugReminderNoNewTitle)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text(hasNew ? s.hugReminderNewCount(newCount) : s.hugReminderNoNewBody)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.muted.opacity(0.42))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}

// MARK: - 快捷入口

struct QuickActionsRow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var showStoryEdit = false
    @State private var showAlbum = false
    @State private var showShare = false

    private var s: Strings { ls.strings }

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "pencil.and.list.clipboard", label: s.quickActionStory) { showStoryEdit = true }
            QuickActionButton(icon: "photo.on.rectangle", label: s.quickActionPhotos) { showAlbum = true }
            QuickActionButton(icon: "paperplane", label: s.quickActionShare) { showShare = true }
        }
        .navigationDestination(isPresented: $showAlbum) { AlbumView() }
        .sheet(isPresented: $showStoryEdit) { StoryEditView().environmentObject(appState) }
        .sheet(isPresented: $showShare) { SharePanelView().environmentObject(appState) }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.green)
                Text(label)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.line, lineWidth: 1)
            )
        }
    }
}

// MARK: - 回忆近况卡

struct MemoryStatusCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    private var hasStory: Bool { appState.story != nil }
    private var albumCount: Int { appState.photoCount }
    private var hasPhotos: Bool { albumCount > 0 }
    private var hasMemory: Bool { hasStory || hasPhotos }
    private var s: Strings { ls.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 左侧插画图标
            ZStack {
                Circle()
                    .fill(AppColors.green.opacity(0.10))
                    .frame(width: 52, height: 52)
                if hasMemory {
                    ZStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.green.opacity(0.60))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.rose.opacity(0.52))
                            .offset(x: 8, y: -8)
                    }
                } else {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.green.opacity(0.55))
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(hasMemory ? s.memoryStatusTitle : s.memoryStatusEmptyTitle)
                    .font(AppFonts.body(15, weight: .medium))
                    .foregroundColor(AppColors.ink)

                Text(bodyText)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
                    .lineSpacing(4)

                Text(s.memoryStatusAddMore)
                    .font(AppFonts.body(12, weight: .medium))
                    .foregroundColor(AppColors.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppColors.greenDeep.opacity(0.78))
                    .cornerRadius(20)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.muted.opacity(0.42))
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { appState.selectedTab = 1 }
    }

    private var bodyText: String {
        switch (hasStory, hasPhotos) {
        case (false, false):
            return s.memoryStatusEmptyBody
        case (true, false):
            return s.memoryStatusBodyStoryOnly(albumCount)
        case (false, true):
            return s.memoryStatusBodyPhotosOnly(albumCount)
        case (true, true):
            return s.memoryStatusBodyBoth(albumCount)
        }
    }
}

// MARK: - 完整纪念空间提示卡

struct FreeUpgradeCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var showEntitlement = false

    private var isPhotoFull: Bool { !appState.canUploadPhoto }
    private var s: Strings { ls.strings }

    var body: some View {
        Button { showEntitlement = true } label: {
            HStack(alignment: .top, spacing: 14) {
                // 左侧小屋插画图标
                ZStack {
                    Circle()
                        .fill(AppColors.muted.opacity(0.07))
                        .frame(width: 52, height: 52)
                    ZStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.muted.opacity(0.48))
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.green.opacity(0.52))
                            .offset(x: -12, y: 8)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isPhotoFull ? s.freeUpgradePhotoFullTitle : s.freeUpgradeMoreTitle)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text(isPhotoFull ? s.freeUpgradePhotoFullBody : s.freeUpgradeMoreBody)
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted)
                        .lineSpacing(2)
                    Text(s.explorePlan)
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.green)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.muted.opacity(0.42))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.035), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.line, lineWidth: 1)
            )
        }
        .navigationDestination(isPresented: $showEntitlement) {
            EntitlementView()
        }
    }
}
