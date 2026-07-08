import SwiftUI

struct SharePanelView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var visibility: Share.Visibility = .link
    @State private var hugEnabled = true
    @State private var showPrivacyConfirm = false
    @State private var pendingCopyOnConfirm = true
    @State private var shareConfirmError = false
    @State private var showSystemShare = false
    @State private var copied = false

    private var s: Strings { ls.strings }
    private var shareURL: String { appState.share?.shareURL ?? "" }
    private var localizedShareURL: String {
        guard !shareURL.isEmpty else { return shareURL }
        let lang = ls.language.rawValue
        return shareURL.contains("?") ? "\(shareURL)&lang=\(lang)" : "\(shareURL)?lang=\(lang)"
    }

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
                                pendingCopyOnConfirm = true
                                showPrivacyConfirm = true
                            } else {
                                copyLink()
                            }
                        } label: {
                            Label(copied ? s.sharePanelCopiedBtn : s.sharePanelCopyBtn, systemImage: copied ? "checkmark" : "link")
                                .font(AppFonts.body(15, weight: .medium))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.greenDeep)
                                .cornerRadius(10)
                        }

                        if visibility == .link {
                            ShareLink(item: URL(string: localizedShareURL) ?? URL(string: "https://pet-memory-psi.vercel.app")!) {
                                Label(s.sharePanelShareBtn, systemImage: "paperplane")
                                    .font(AppFonts.body(15, weight: .medium))
                                    .foregroundColor(AppColors.greenDeep)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.green.opacity(0.08))
                                    .cornerRadius(10)
                            }
                        } else {
                            Button {
                                pendingCopyOnConfirm = false
                                showPrivacyConfirm = true
                            } label: {
                                Label(s.sharePanelShareBtn, systemImage: "paperplane")
                                    .font(AppFonts.body(15, weight: .medium))
                                    .foregroundColor(AppColors.greenDeep)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.green.opacity(0.08))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    #if DEBUG
                    if !localizedShareURL.isEmpty, let url = URL(string: localizedShareURL) {
                        Button {
                            openURL(url)
                        } label: {
                            Label("预览 H5 页面", systemImage: "safari")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                        }
                        .padding(.top, 16)
                    }
                    #endif

                    Spacer()
                }
            }
            .navigationTitle(s.sharePanelNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s.close) { dismiss() }.foregroundColor(AppColors.muted)
                }
            }
            .onAppear {
                visibility = appState.share?.visibility ?? .link
                hugEnabled = appState.share?.hugEnabled ?? true
            }
            .onChange(of: visibility) { saveShare() }
            .onChange(of: hugEnabled) { saveShare() }
            .alert(s.sharePanelPrivacyAlertTitle, isPresented: $showPrivacyConfirm) {
                Button(s.sharePanelPrivacyConfirmBtn) {
                    Task { @MainActor in
                        guard let token = KeychainHelper.loadToken(),
                              let petId = appState.currentPet?.id else { return }
                        do {
                            try await APIClient.shared.updateShare(token: token, petId: petId,
                                                                   visibility: "LINK", hugEnabled: hugEnabled)
                            appState.share?.visibility = .link
                            visibility = .link
                            if pendingCopyOnConfirm { copyLink() } else { showSystemShare = true }
                        } catch {
                            shareConfirmError = true
                        }
                    }
                }
                Button(s.cancel, role: .cancel) {}
            } message: {
                Text(s.sharePanelPrivacyAlertBody)
            }
            .alert(s.sharePanelSaveErrorTitle, isPresented: $shareConfirmError) {
                Button(s.ok, role: .cancel) {}
            } message: {
                Text(s.sharePanelSaveErrorBody)
            }
            .sheet(isPresented: $showSystemShare) {
                if let url = URL(string: localizedShareURL), !localizedShareURL.isEmpty {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = localizedShareURL
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }

    private func saveShare() {
        guard let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        let visStr = visibility == .link ? "LINK" : "PRIVATE"
        let enabled = hugEnabled
        Task {
            try? await APIClient.shared.updateShare(token: token, petId: petId,
                                                     visibility: visStr, hugEnabled: enabled)
        }
    }
}

struct SharePreviewCard: View {
    let petName: String
    @EnvironmentObject var ls: LanguageStore

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
                Text(ls.strings.sharePanelPreviewSubtitle)
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
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(ls.strings.sharePanelVisibilityTitle)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                Text(visibility == .link ? ls.strings.sharePanelVisibilityLink : ls.strings.sharePanelVisibilityPrivate)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            Spacer()
            Menu {
                Button(ls.strings.sharePanelVisibilityLink) { visibility = .link }
                Button(ls.strings.sharePanelVisibilityPrivate) { visibility = .private }
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
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(ls.strings.sharePanelHugTitle)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                Text(ls.strings.sharePanelHugSubtitle)
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

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
