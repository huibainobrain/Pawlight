import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var showStoryEdit = false
    @State private var showAlbum = false
    @State private var showMailbox = false
    @State private var showHugs = false
    @State private var showMemorialEdit = false
    @State private var showOnboarding = false

    private var s: Strings { ls.strings }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                if !appState.hasPet {
                    MemoryUnboardedView(showOnboarding: $showOnboarding)
                }
                if appState.hasPet {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            MemoryHeaderView(showMemorialEdit: $showMemorialEdit)

                            VStack(spacing: 12) {
                                ShareGuideCard()

                                MemorySectionCard(title: s.memorySectionStory, icon: "book.fill") {
                                    showStoryEdit = true
                                } content: {
                                    if let story = appState.story, !story.content.isEmpty {
                                        Text(story.content)
                                            .font(AppFonts.body(14))
                                            .foregroundStyle(AppColors.ink)
                                            .lineSpacing(5)
                                            .lineLimit(3)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(s.memoryStoryEmpty)
                                                .font(AppFonts.body(14))
                                                .foregroundStyle(AppColors.muted)
                                                .lineSpacing(4)
                                            Button { showStoryEdit = true } label: {
                                                Text(s.memoryWriteStory)
                                                    .font(AppFonts.body(14, weight: .medium))
                                                    .foregroundStyle(AppColors.greenDeep)
                                            }
                                        }
                                    }
                                }

                                MemorySectionCard(title: s.memorySectionPhotos, icon: "photo.on.rectangle.fill") {
                                    showAlbum = true
                                } content: {
                                    let albumPhotos = appState.photos.filter { $0.type == .album }
                                    if albumPhotos.isEmpty {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(s.memoryPhotosEmpty)
                                                .font(AppFonts.body(14))
                                                .foregroundStyle(AppColors.muted)
                                                .lineSpacing(4)
                                            Button { showAlbum = true } label: {
                                                Text(s.memoryAddPhotos)
                                                    .font(AppFonts.body(14, weight: .medium))
                                                    .foregroundStyle(AppColors.greenDeep)
                                            }
                                        }
                                    } else {
                                        VStack(alignment: .leading, spacing: 8) {
                                            AlbumThumbnailGrid(photos: albumPhotos)
                                            Text(s.albumCapacity(albumPhotos.count, appState.photoLimit))
                                                .font(AppFonts.body(12))
                                                .foregroundStyle(AppColors.muted)
                                        }
                                    }
                                }

                                MemorySectionCard(
                                    title: s.memorySectionMailbox,
                                    icon: "envelope.fill",
                                    lockedBadge: !appState.mailboxEnabled
                                ) {
                                    showMailbox = true
                                } content: {
                                    if appState.mailboxEnabled {
                                        if appState.letters.isEmpty {
                                            Text(s.memoryMailboxEmpty)
                                                .font(AppFonts.body(14))
                                                .foregroundStyle(AppColors.muted)
                                                .lineSpacing(4)
                                        } else {
                                            VStack(alignment: .leading, spacing: 4) {
                                                let latest = appState.letters.first
                                                Text(latest?.title.flatMap { $0.isEmpty ? nil : $0 } ?? s.memoryLetterDefaultTitle)
                                                    .font(AppFonts.body(14, weight: .medium))
                                                    .foregroundStyle(AppColors.ink)
                                                    .lineLimit(1)
                                                Text(s.memoryLetterCount(appState.letters.count))
                                                    .font(AppFonts.body(12))
                                                    .foregroundStyle(AppColors.muted)
                                            }
                                        }
                                    } else {
                                        Text(s.memoryMailboxLocked)
                                            .font(AppFonts.body(14))
                                            .foregroundStyle(AppColors.muted)
                                            .lineSpacing(4)
                                    }
                                }

                                MemorySectionCard(title: s.memorySectionHugs, icon: "heart.fill") {
                                    showHugs = true
                                } content: {
                                    if appState.hugs.isEmpty {
                                        Text(s.memoryHugsEmpty)
                                            .font(AppFonts.body(14))
                                            .foregroundStyle(AppColors.muted)
                                            .lineSpacing(4)
                                    } else {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if appState.newHugCount > 0 {
                                                HStack(spacing: 6) {
                                                    Circle()
                                                        .fill(AppColors.rose)
                                                        .frame(width: 6, height: 6)
                                                    Text(s.memoryNewHugs(appState.newHugCount))
                                                        .font(AppFonts.body(13, weight: .medium))
                                                        .foregroundStyle(AppColors.rose)
                                                }
                                            }
                                            Text(s.memoryHugsTotal(appState.hugs.count))
                                                .font(AppFonts.body(14))
                                                .foregroundStyle(AppColors.muted)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 48)
                        }
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showStoryEdit) { StoryEditView() }
            .fullScreenCover(isPresented: $showMemorialEdit) { MemorialSentenceEditView() }
            .navigationDestination(isPresented: $showAlbum) { AlbumView() }
            .navigationDestination(isPresented: $showMailbox) {
                appState.mailboxEnabled ? AnyView(MailboxView()) : AnyView(MailboxLockedView())
            }
            .navigationDestination(isPresented: $showHugs) { HugsView() }
        }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingStartView() }
        .onChange(of: appState.hasPet) { _, hasPet in
            if hasPet { showOnboarding = false }
        }
        .onChange(of: showAlbum)   { _, _ in syncTabBar() }
        .onChange(of: showMailbox) { _, _ in syncTabBar() }
        .onChange(of: showHugs)    { _, _ in syncTabBar() }
    }

    private func syncTabBar() {
        appState.tabBarHidden = showAlbum || showMailbox || showHugs
    }
}

// MARK: - 未入驻空态

struct MemoryUnboardedView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.green.opacity(0.35))
            VStack(spacing: 10) {
                Text(s.homeUnboardedTitle)
                    .font(AppFonts.serif(20, weight: .medium))
                    .foregroundStyle(AppColors.ink)
                Text(s.homeUnboardedBody)
                    .font(AppFonts.body(14))
                    .foregroundStyle(AppColors.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Button {
                showOnboarding = true
            } label: {
                Text(s.createKeepsake)
                    .font(AppFonts.body(16, weight: .medium))
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.greenDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 头图区

struct MemoryHeaderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Binding var showMemorialEdit: Bool

    private var s: Strings { ls.strings }

    private var datesLine: String? {
        guard let pet = appState.currentPet else { return nil }
        let arrived = pet.metOrAdoptionDate.flatMap { yearString($0) }
        let left = pet.passedAwayDate.flatMap { yearString($0) }
        if let a = arrived, let l = left { return "\(a) — \(l)" }
        if let l = left { return s.leftLabel(l) }
        if let a = arrived { return s.arrivedLabel(a) }
        return nil
    }

    private func yearString(_ d: PartialDate) -> String? {
        guard let v = d.value, !v.isEmpty else { return nil }
        let year = String(v.prefix(4))
        return year.isEmpty ? nil : year
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 极轻背景氛围
                VStack {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.green.opacity(0.18))
                            .rotationEffect(.degrees(-38))
                            .offset(x: 28, y: 22)
                        Spacer()
                        Circle()
                            .fill(AppColors.muted.opacity(0.10))
                            .frame(width: 3, height: 3)
                            .offset(x: -36, y: 18)
                    }
                    Spacer()
                }

                VStack(spacing: 0) {
                    // 主照片 + 装饰
                    ZStack {
                        // 外光晕
                        Circle()
                            .fill(AppColors.green.opacity(0.06))
                            .frame(width: 164, height: 164)

                        // 绿色装饰环
                        Circle()
                            .fill(AppColors.green.opacity(0.22))
                            .frame(width: 148, height: 148)

                        // 内白分隔
                        Circle()
                            .fill(AppColors.paper)
                            .frame(width: 136, height: 136)

                        // 用户上传主照片
                        if let photo = appState.currentPet?.mainPhoto {
                            AsyncImage(url: URL(string: photo.url)) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                default:
                                    pawPlaceholder
                                }
                            }
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AppColors.paperSoft)
                                .frame(width: 130, height: 130)
                            pawPlaceholder
                        }

                        // 左下：叶片装饰
                        ZStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppColors.green.opacity(0.46))
                                .rotationEffect(.degrees(32))
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.green.opacity(0.32))
                                .rotationEffect(.degrees(12))
                                .offset(x: -10, y: 8)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(AppColors.green.opacity(0.22))
                                .rotationEffect(.degrees(52))
                                .offset(x: 6, y: 14)
                        }
                        .offset(x: -60, y: 52)

                        // 右下：小花朵装饰
                        ZStack {
                            HeaderFlower(size: 17).offset(x: 2, y: -4)
                            HeaderFlower(size: 13).offset(x: -10, y: 9)
                            HeaderFlower(size: 10).offset(x: 10, y: 10)
                        }
                        .offset(x: 60, y: 52)

                        // 顶部散点
                        Image(systemName: "sparkle")
                            .font(.system(size: 7, weight: .ultraLight))
                            .foregroundStyle(AppColors.muted.opacity(0.28))
                            .offset(x: -64, y: -46)

                        Circle()
                            .fill(HomeStarColor.opacity(0.32))
                            .frame(width: 3)
                            .offset(x: 58, y: -52)
                    }
                    .padding(.top, 36)

                    // 宠物名字
                    Text(appState.currentPet?.name ?? "")
                        .font(AppFonts.serif(26, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .padding(.top, 20)

                    // 日期（如有）
                    if let dates = datesLine {
                        Text(dates)
                            .font(AppFonts.body(12))
                            .foregroundStyle(AppColors.muted.opacity(0.55))
                            .padding(.top, 5)
                    }

                    // 纪念语 + 编辑入口
                    Button { showMemorialEdit = true } label: {
                        HStack(spacing: 5) {
                            let sentence = appState.currentPet?.memorialSentence ?? ""
                            Text(sentence.isEmpty ? s.memorySentencePlaceholder : sentence)
                                .font(AppFonts.body(14))
                                .foregroundStyle(sentence.isEmpty ? AppColors.muted.opacity(0.42) : AppColors.muted)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.muted.opacity(0.40))
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 9)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private var pawPlaceholder: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 40))
            .foregroundStyle(AppColors.green.opacity(0.32))
    }
}

// 小花朵：5瓣椭圆 + 暖黄圆心
private struct HeaderFlower: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                    .frame(width: size * 0.46, height: size * 0.58)
                    .offset(y: -(size * 0.24))
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Color(red: 0.95, green: 0.86, blue: 0.58).opacity(0.88))
                .frame(width: size * 0.36)
        }
        .frame(width: size, height: size)
    }
}

private let HomeStarColor = Color(red: 0.80, green: 0.72, blue: 0.54)

// MARK: - 分享引导卡

struct ShareGuideCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var showShare = false
    @State private var showPrivacyAlert = false

    private var s: Strings { ls.strings }
    private var hasContent: Bool {
        let hasStory = appState.story.map { !$0.content.isEmpty } ?? false
        let hasPhotos = !appState.photos.filter { $0.type == .album }.isEmpty
        return hasStory || hasPhotos
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.green.opacity(0.12))
                        .frame(width: 44, height: 44)
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.green.opacity(0.55))
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(hasContent ? s.memoryShareCardTitle : s.memoryShareCardNoContent)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                    Text(hasContent ? s.memoryShareCardSubtitle : s.memoryShareCardSubtitleEmpty)
                        .font(AppFonts.body(13))
                        .foregroundStyle(AppColors.muted)
                        .lineSpacing(3)
                }
            }

            Button {
                if appState.share?.visibility == .private {
                    showPrivacyAlert = true
                } else {
                    showShare = true
                }
            } label: {
                Text(s.memoryShareBtn)
                    .font(AppFonts.body(15, weight: .medium))
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppColors.greenDeep.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.line, lineWidth: 1))
        .sheet(isPresented: $showShare) { SharePanelView() }
        .alert(s.memorySharePrivacyAlertTitle, isPresented: $showPrivacyAlert) {
            Button(s.memorySharePrivacyConfirmBtn) { showShare = true }
            Button(s.cancel, role: .cancel) {}
        } message: {
            Text(s.memorySharePrivacyAlertBody)
        }
    }
}

// MARK: - Section 卡片

struct MemorySectionCard<Content: View>: View {
    let title: String
    let icon: String
    let lockedBadge: Bool
    let onTap: () -> Void
    let content: Content
    @EnvironmentObject var ls: LanguageStore

    init(
        title: String,
        icon: String,
        lockedBadge: Bool = false,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.lockedBadge = lockedBadge
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppColors.green.opacity(0.10))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.green.opacity(0.68))
                    }
                    .padding(.trailing, 10)

                    Text(title)
                        .font(AppFonts.body(15, weight: .medium))
                        .foregroundStyle(AppColors.ink)

                    if lockedBadge {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                            Text(ls.strings.memoryLockedBadge)
                                .font(AppFonts.body(10))
                        }
                        .foregroundStyle(AppColors.muted.opacity(0.55))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.muted.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(.leading, 7)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.muted.opacity(0.42))
                }

                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.line, lineWidth: 1))
    }
}

// MARK: - 相册缩略图

struct AlbumThumbnailGrid: View {
    let photos: [Photo]
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        if photos.isEmpty {
            Text(ls.strings.memoryPhotosEmpty)
                .font(AppFonts.body(14))
                .foregroundStyle(AppColors.muted)
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 4
            ) {
                ForEach(photos.prefix(9)) { photo in
                    AsyncImage(url: URL(string: photo.thumbnailURL)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        AppColors.line
                    }
                    .frame(height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
