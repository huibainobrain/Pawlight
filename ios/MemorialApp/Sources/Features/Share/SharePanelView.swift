import SwiftUI

struct SharePanelView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var visibility: Share.Visibility = .link
    @State private var hugEnabled = true
    @State private var showPrivacyConfirm = false
    @State private var copied = false

    private var shareURL: String { appState.share?.shareURL ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    SharePreviewCard(petName: appState.currentPet?.name ?? "")
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    VStack(spacing: 0) {
                        VisibilityRow(visibility: $visibility)
                        Divider().padding(.horizontal, 20)
                        HugToggleRow(hugEnabled: $hugEnabled)
                    }
                    .background(AppColors.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        Button {
                            if visibility == .private {
                                showPrivacyConfirm = true
                            } else {
                                copyLink()
                            }
                        } label: {
                            Label(copied ? "已复制" : "复制链接", systemImage: copied ? "checkmark" : "link")
                                .font(AppFonts.body(15, weight: .medium))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.greenDeep)
                                .cornerRadius(10)
                        }

                        ShareLink(item: URL(string: shareURL) ?? URL(string: "https://pet-memory-psi.vercel.app")!) {
                            Label("分享给好友", systemImage: "paperplane")
                                .font(AppFonts.body(15, weight: .medium))
                                .foregroundColor(AppColors.greenDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.green.opacity(0.08))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationTitle("分享纪念页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }.foregroundColor(AppColors.muted)
                }
            }
            .alert("改为链接可见", isPresented: $showPrivacyConfirm) {
                Button("确认改为链接可见") {
                    visibility = .link
                    copyLink()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("当前设置为仅自己可见。分享前需要改为通过链接可见，确认吗？")
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = shareURL
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }
}

struct SharePreviewCard: View {
    let petName: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(petName)
                    .font(AppFonts.serif(17, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text("的纪念星球")
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
    }
}

struct VisibilityRow: View {
    @Binding var visibility: Share.Visibility

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("谁可以看见TA")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                Text(visibility == .link ? "通过链接可见" : "仅自己可见")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            Spacer()
            Menu {
                Button("通过链接可见") { visibility = .link }
                Button("仅自己可见") { visibility = .private }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct HugToggleRow: View {
    @Binding var hugEnabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("允许访客抱抱TA")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                Text("访客可以用抱抱表达心意")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            Spacer()
            Toggle("", isOn: $hugEnabled)
                .tint(AppColors.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
