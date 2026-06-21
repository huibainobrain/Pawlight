import SwiftUI

struct MineView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEntitlement = false
    @State private var showPrivacy = false
    @State private var showPetProfile = false
    @State private var showDeleteAlert = false
    @Environment(\.openURL) var openURL

    private let privacyURL = URL(string: "https://pet-memory-psi.vercel.app/privacy")!
    private let feedbackEmail = URL(string: "mailto:ntuwangyiming@gmail.com?subject=星屿纪念反馈")!

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                List {
                    Section {
                        AccountHeaderRow()
                    }
                    .listRowBackground(AppColors.white)

                    Section("我的宠物") {
                        if appState.hasPet {
                            NavigationLink(destination: PetProfileView()) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(AppColors.green.opacity(0.12)).frame(width: 36, height: 36)
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.green)
                                    }
                                    Text(appState.currentPet?.name ?? "")
                                        .font(AppFonts.body(15))
                                        .foregroundColor(AppColors.ink)
                                }
                            }
                            Button {
                                // Show unavailable alert
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(AppColors.line).frame(width: 36, height: 36)
                                        Image(systemName: "plus")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.muted)
                                    }
                                    Text("新增宠物")
                                        .font(AppFonts.body(15))
                                        .foregroundColor(AppColors.muted)
                                    Spacer()
                                    Text("即将开放")
                                        .font(AppFonts.body(12))
                                        .foregroundColor(AppColors.muted)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppColors.line)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .listRowBackground(AppColors.white)

                    Section("纪念空间") {
                        NavigationLink(destination: EntitlementView()) {
                            HStack(spacing: 12) {
                                Image(systemName: appState.isPaid ? "star.fill" : "star")
                                    .foregroundColor(AppColors.gold)
                                    .frame(width: 20)
                                Text(appState.isPaid ? "完整纪念空间（已开通）" : "权益与升级")
                                    .font(AppFonts.body(15))
                                    .foregroundColor(AppColors.ink)
                            }
                        }
                        NavigationLink(destination: PrivacySettingsView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppColors.muted)
                                    .frame(width: 20)
                                Text("权限设置")
                                    .font(AppFonts.body(15))
                                    .foregroundColor(AppColors.ink)
                            }
                        }
                    }
                    .listRowBackground(AppColors.white)

                    #if DEBUG
                    Section("开发调试") {
                        Button {
                            appState.resetAll()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(AppColors.rose)
                                    .frame(width: 20)
                                Text("重置（回到注册流程）")
                                    .font(AppFonts.body(15))
                                    .foregroundColor(AppColors.rose)
                            }
                        }
                    }
                    .listRowBackground(AppColors.white)
                    #endif

                    Section("支持") {
                        MineSupportRow(icon: "questionmark.circle", label: "客服与反馈") { openURL(feedbackEmail) }
                        MineSupportRow(icon: "doc.text", label: "用户协议") { openURL(privacyURL) }
                        MineSupportRow(icon: "hand.raised", label: "隐私政策") { openURL(privacyURL) }
                        MineSupportRow(icon: "trash", label: "注销账号", tint: AppColors.rose) { showDeleteAlert = true }
                    }
                    .listRowBackground(AppColors.white)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppColors.paper)
            }
            .navigationTitle("我的")
            .alert("注销账号", isPresented: $showDeleteAlert) {
                Button("确认注销", role: .destructive) { appState.resetAll() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("注销后将退出登录并清除本地数据，账号内容仍保留在服务器。")
            }
        }
    }
}

struct AccountHeaderRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.green.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.green)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.currentUser?.nickname ?? "Apple 用户")
                    .font(AppFonts.body(16, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text("Apple 账号登录")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MineSupportRow: View {
    let icon: String
    let label: String
    var tint: Color = AppColors.muted
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .frame(width: 20)
                Text(label)
                    .font(AppFonts.body(15))
                    .foregroundColor(tint == AppColors.muted ? AppColors.ink : tint)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.muted)
            }
        }
    }
}
