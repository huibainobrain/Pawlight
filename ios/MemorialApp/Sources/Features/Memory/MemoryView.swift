import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showStoryEdit = false
    @State private var showAlbum = false
    @State private var showMailbox = false
    @State private var showHugs = false
    @State private var showMemorialEdit = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                if !appState.hasPet {
                    MemoryUnboardedView()
                }
                if appState.hasPet {
                    ScrollView {
                    VStack(spacing: 0) {
                        MemoryHeaderView(showMemorialEdit: $showMemorialEdit)

                        ShareGuideCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        MemorySectionCard(title: "TA的故事", icon: "text.quote") {
                            showStoryEdit = true
                        } content: {
                            if let story = appState.story, !story.content.isEmpty {
                                Text(story.content)
                                    .font(AppFonts.body(15))
                                    .foregroundColor(AppColors.ink)
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("还没有写下TA的故事。\n可以从第一次见到TA，或者最想念TA的一件小事开始。")
                                        .font(AppFonts.body(14))
                                        .foregroundColor(AppColors.muted)
                                        .lineSpacing(4)
                                    Button { showStoryEdit = true } label: {
                                        Text("写下TA的故事")
                                            .font(AppFonts.body(14, weight: .medium))
                                            .foregroundColor(AppColors.greenDeep)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        MemorySectionCard(title: "照片回忆", icon: "photo.on.rectangle") {
                            showAlbum = true
                        } content: {
                            let albumPhotos = appState.photos.filter { $0.type == .album }
                            if albumPhotos.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("还没有添加照片。\n放一张TA的照片吧。")
                                        .font(AppFonts.body(14))
                                        .foregroundColor(AppColors.muted)
                                        .lineSpacing(4)
                                    Button { showAlbum = true } label: {
                                        Text("添加照片")
                                            .font(AppFonts.body(14, weight: .medium))
                                            .foregroundColor(AppColors.greenDeep)
                                    }
                                }
                            } else {
                                AlbumThumbnailGrid(photos: albumPhotos)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        MemorySectionCard(title: "天堂信箱", icon: "envelope.fill") {
                            showMailbox = true
                        } content: {
                            if appState.mailboxEnabled {
                                Text(appState.letters.isEmpty ? "想说的话，慢慢写在这里。" : "\(appState.letters.count) 封信")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                            } else {
                                Text("开启完整纪念空间后，可以把想对TA说的话慢慢留在这里。")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        MemorySectionCard(title: "抱抱记录", icon: "heart.fill") {
                            showHugs = true
                        } content: {
                            if appState.hugs.isEmpty {
                                Text("还没有收到抱抱。\n分享给也记得TA的人，他们可以轻轻抱抱TA。")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                            } else {
                                Text("TA收到了 \(appState.hugs.count) 个抱抱")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                    }  // ScrollView
                }  // if appState.hasPet
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showStoryEdit) { StoryEditView() }
            .sheet(isPresented: $showMemorialEdit) { MemorialSentenceEditView() }
            .navigationDestination(isPresented: $showAlbum) { AlbumView() }
            .navigationDestination(isPresented: $showMailbox) {
                appState.mailboxEnabled ? AnyView(MailboxView()) : AnyView(MailboxLockedView())
            }
            .navigationDestination(isPresented: $showHugs) { HugsView() }
        }
    }
}

// MARK: - 未入驻空态

struct MemoryUnboardedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 48))
                .foregroundColor(AppColors.green.opacity(0.35))
            VStack(spacing: 10) {
                Text("TA的回忆，等你来记录")
                    .font(AppFonts.serif(20, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text("创建星球后，这里可以留下\nTA的故事、照片和你写给TA的话。")
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 头图区

struct MemoryHeaderView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showMemorialEdit: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.green.opacity(0.18), AppColors.blue.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 260)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.white.opacity(0.9))
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.08), radius: 12)
                    if let photo = appState.currentPet?.mainPhoto {
                        AsyncImage(url: URL(string: photo.url)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.green.opacity(0.5))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.green.opacity(0.5))
                    }
                }
                VStack(spacing: 6) {
                    Text(appState.currentPet?.name ?? "")
                        .font(AppFonts.serif(22, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Button {
                        showMemorialEdit = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(
                                appState.currentPet?.memorialSentence?.isEmpty == false
                                    ? (appState.currentPet?.memorialSentence ?? "")
                                    : "写一句纪念语"
                            )
                            .font(AppFonts.body(14))
                            .foregroundColor(AppColors.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.muted)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - 分享引导卡

struct ShareGuideCard: View {
    @EnvironmentObject var appState: AppState
    @State private var showShare = false
    @State private var showPrivacyAlert = false

    private var hasContent: Bool {
        let hasStory = appState.story.map { !$0.content.isEmpty } ?? false
        let hasPhotos = !appState.photos.filter { $0.type == .album }.isEmpty
        return hasStory || hasPhotos
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hasContent ? "分享给也记得TA的人" : "补充一点回忆后，也可以分享给记得TA的人")
                .font(AppFonts.body(14, weight: .medium))
                .foregroundColor(AppColors.ink)
            Text(hasContent ? "他们可以看看TA，也轻轻抱抱TA。" : "先写下一点故事或放一张照片，会让纪念页更完整。")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.muted)
                .lineSpacing(3)
            Button {
                if appState.share?.visibility == .private {
                    showPrivacyAlert = true
                } else {
                    showShare = true
                }
            } label: {
                Text("分享纪念页")
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.greenDeep)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(AppColors.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
        .sheet(isPresented: $showShare) { SharePanelView() }
        .alert("需要调整分享设置", isPresented: $showPrivacyAlert) {
            Button("进入分享设置") { showShare = true }
            Button("取消", role: .cancel) {}
        } message: {
            Text("当前设置为仅自己可见，分享前需要改为通过链接可见。")
        }
    }
}

// MARK: - Section 卡片

struct MemorySectionCard<Content: View>: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.green)
                        Text(title)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.ink)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.muted)
                }
            }
            content
        }
        .padding(16)
        .background(AppColors.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
    }
}

// MARK: - 相册缩略图

struct AlbumThumbnailGrid: View {
    let photos: [Photo]

    var body: some View {
        if photos.isEmpty {
            Text("还没有添加照片，放一张TA的照片吧。")
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.muted)
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(photos.prefix(9)) { photo in
                    AsyncImage(url: URL(string: photo.thumbnailURL)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        AppColors.line
                    }
                    .frame(height: 80)
                    .clipped()
                    .cornerRadius(4)
                }
            }
        }
    }
}
