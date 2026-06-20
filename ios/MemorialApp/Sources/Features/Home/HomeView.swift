import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                if appState.hasPet {
                    HomeCreatedView()
                } else {
                    HomeUnboardedView()
                }
            }
        }
    }
}

// MARK: - 未入驻

struct HomeUnboardedView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.green.opacity(0.15))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(AppColors.green.opacity(0.08))
                        .frame(width: 200, height: 200)
                    Image(systemName: "sparkles")
                        .font(.system(size: 52))
                        .foregroundColor(AppColors.green)
                }
                VStack(spacing: 12) {
                    Text("回来看看TA")
                        .font(AppFonts.serif(26, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text("把想念慢慢放在这里")
                        .font(AppFonts.body(16))
                        .foregroundColor(AppColors.muted)
                }
            }
            Spacer()
            VStack(spacing: 16) {
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
                Button("稍后再说") {}
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingStartView()
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
                        .onTapGesture { showHugs = true }
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
            }
        }
        .padding(.vertical, 8)
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
            Text("有 \(count) 个新抱抱")
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
    @State private var showShare = false
    @State private var showAlbum = false

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "text.quote", label: "写给TA") {}
            QuickActionButton(icon: "photo", label: "放张照片") { showAlbum = true }
            QuickActionButton(icon: "paperplane", label: "分享") { showShare = true }
        }
        .sheet(isPresented: $showShare) {
            SharePanelView().environmentObject(appState)
        }
        .sheet(isPresented: $showAlbum) {
            AlbumView().environmentObject(appState)
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
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("更多照片，更完整的纪念空间")
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
}
