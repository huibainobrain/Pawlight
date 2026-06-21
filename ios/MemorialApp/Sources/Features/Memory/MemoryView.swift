import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showStoryEdit = false
    @State private var showAlbum = false
    @State private var showMailbox = false
    @State private var showHugs = false
    @State private var showShare = false
    @State private var showMemorialEdit = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        MemoryHeaderView(showMemorialEdit: $showMemorialEdit, showShare: $showShare)

                        MemoryQuickActions(
                            showStoryEdit: $showStoryEdit,
                            showAlbum: $showAlbum,
                            showShare: $showShare
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

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
                                Text("还没有写下TA的故事。\n可以从第一次见到TA开始。")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        MemorySectionCard(title: "照片回忆", icon: "photo.on.rectangle") {
                            showAlbum = true
                        } content: {
                            AlbumThumbnailGrid(photos: appState.photos.filter { $0.type == .album })
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        MemorySectionCard(
                            title: appState.mailboxEnabled ? "天堂信箱" : "天堂信箱（付费开启）",
                            icon: "envelope.fill"
                        ) {
                            showMailbox = true
                        } content: {
                            if appState.mailboxEnabled {
                                Text(appState.letters.isEmpty ? "想说的话，慢慢写在这里。" : "\(appState.letters.count) 封信")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.muted)
                                    Text("开启完整纪念空间后可用")
                                        .font(AppFonts.body(14))
                                        .foregroundColor(AppColors.muted)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        MemorySectionCard(title: "抱抱记录", icon: "heart.fill") {
                            showHugs = true
                        } content: {
                            if appState.hugs.isEmpty {
                                Text("还没有人抱抱TA，分享后朋友们可以来抱抱。")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                            } else {
                                Text("共 \(appState.hugs.count) 个抱抱")
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showStoryEdit) { StoryEditView() }
            .sheet(isPresented: $showMemorialEdit) { MemorialSentenceEditView() }
            .sheet(isPresented: $showShare) { SharePanelView() }
            .navigationDestination(isPresented: $showAlbum) { AlbumView() }
            .navigationDestination(isPresented: $showMailbox) {
                appState.mailboxEnabled ? AnyView(MailboxView()) : AnyView(MailboxLockedView())
            }
            .navigationDestination(isPresented: $showHugs) { HugsView() }
        }
    }
}

// MARK: - 头图区

struct MemoryHeaderView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showMemorialEdit: Bool
    @Binding var showShare: Bool

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

// MARK: - 快捷操作

struct MemoryQuickActions: View {
    @Binding var showStoryEdit: Bool
    @Binding var showAlbum: Bool
    @Binding var showShare: Bool

    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "text.quote", label: "写TA的故事") { showStoryEdit = true }
            QuickActionButton(icon: "photo.badge.plus", label: "添加照片") { showAlbum = true }
            QuickActionButton(icon: "paperplane", label: "分享给也记得TA的人") { showShare = true }
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
