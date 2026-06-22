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
    @State private var showLearnMore = false

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
                    Text("回来看看TA，\n把想念慢慢放在这里。")
                        .font(AppFonts.serif(22, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                    Text("这里不是任务系统，也不是社交广场。\n它只是一个安静的位置，留给你和那只小动物。")
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
                    Text("为TA创建星球")
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.greenDeep)
                        .cornerRadius(12)
                }
                Button("先了解一下") {
                    showLearnMore = true
                }
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.muted)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showLearnMore) {
            LearnMoreSheet()
        }
    }
}

// MARK: - 了解一下

struct LearnMoreSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("关于星屿纪念")
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
                LearnMoreItem(
                    icon: "moon.stars.fill",
                    title: "一个安静的地方",
                    detail: "不是说说，不是动态。只是一个你可以随时回来、静静想念TA的空间。"
                )
                LearnMoreItem(
                    icon: "photo.on.rectangle",
                    title: "留下TA的样子",
                    detail: "上传照片、写下TA的故事和纪念语——只属于你和TA。"
                )
                LearnMoreItem(
                    icon: "heart.fill",
                    title: "分享给也记得TA的人",
                    detail: "把纪念页分享给家人或朋友，让他们也能来看看，留下抱抱。"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("好，我知道了")
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
                Text(detail)
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
                    .lineSpacing(3)
            }
        }
    }
}

// MARK: - 已入驻

struct HomeCreatedView: View {
    @EnvironmentObject var appState: AppState
    @State private var showHugs = false
    @State private var showMemory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PlanetWindowView()
                    .padding(.top, 16)

                if appState.newHugCount > 0 {
                    NewHugCard(count: appState.newHugCount)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .onTapGesture {
                            appState.newHugCount = 0
                            showHugs = true
                        }
                }

                QuickActionsRow()
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                if appState.entitlement?.isFree == true {
                    FreeUpgradeCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                Spacer(minLength: 40)
            }
        }
        .navigationDestination(isPresented: $showHugs) {
            HugsView()
        }
    }
}

// MARK: - 星球观察窗

struct PlanetWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.green.opacity(0.2), AppColors.blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(AppColors.paperSoft)
                    .frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)

                if let photo = appState.currentPet?.mainPhoto {
                    AsyncImage(url: URL(string: photo.url)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.green.opacity(0.4))
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.green.opacity(0.4))
                }
            }

            VStack(spacing: 6) {
                Text(appState.currentPet?.name ?? "")
                    .font(AppFonts.serif(22, weight: .medium))
                    .foregroundColor(AppColors.ink)
                if let sentence = appState.currentPet?.memorialSentence, !sentence.isEmpty {
                    Text(sentence)
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Text("轻触，看看TA的回忆")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.muted.opacity(0.45))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedTab = 1
        }
    }
}

// MARK: - 新抱抱卡片

struct NewHugCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundColor(AppColors.rose)
                .font(.system(size: 18))
            Text("有 \(count) 个新的抱抱")
                .font(AppFonts.body(15))
                .foregroundColor(AppColors.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.rose.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.rose.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 快捷操作

struct QuickActionsRow: View {
    @EnvironmentObject var appState: AppState
    @State private var showStoryEdit = false
    @State private var showShare = false

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "text.quote", label: "写故事") { showStoryEdit = true }
            QuickActionButton(icon: "photo", label: "放照片") { appState.selectedTab = 1 }
            QuickActionButton(icon: "paperplane", label: "分享") { showShare = true }
        }
        .sheet(isPresented: $showStoryEdit) {
            StoryEditView().environmentObject(appState)
        }
        .sheet(isPresented: $showShare) {
            SharePanelView().environmentObject(appState)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.green)
                Text(label)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.line, lineWidth: 1)
            )
        }
    }
}

// MARK: - 免费升级卡

struct FreeUpgradeCard: View {
    @EnvironmentObject var appState: AppState
    @State private var showEntitlement = false

    private var isPhotoFull: Bool { !appState.canUploadPhoto }

    var body: some View {
        Button { showEntitlement = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPhotoFull ? "照片已到免费上限" : "想留下更多照片时")
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text("了解完整纪念空间")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.green)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.green.opacity(0.07))
            .cornerRadius(10)
        }
        .navigationDestination(isPresented: $showEntitlement) {
            EntitlementView()
        }
    }
}
