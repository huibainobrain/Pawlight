import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var visibility: Share.Visibility = .link
    @State private var hugEnabled = true
    @State private var isSaving = false
    @State private var saveError = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            Form {
                Section("谁可以看见TA") {
                    Picker("可见范围", selection: $visibility) {
                        Text("通过链接可见").tag(Share.Visibility.link)
                        Text("仅自己可见").tag(Share.Visibility.private)
                    }
                    .pickerStyle(.inline)
                }
                .listRowBackground(AppColors.white)

                Section {
                    Toggle("允许访客抱抱TA", isOn: $hugEnabled)
                        .tint(AppColors.green)
                } footer: {
                    Text("关闭后，H5 页面仍可访问，但访客无法发起抱抱。")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted)
                }
                .listRowBackground(AppColors.white)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.paper)
        }
        .navigationTitle("权限设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { save() } label: {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("保存")
                            .foregroundColor(AppColors.greenDeep)
                            .fontWeight(.medium)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            visibility = appState.share?.visibility ?? .link
            hugEnabled = appState.share?.hugEnabled ?? true
        }
        .alert("保存失败", isPresented: $saveError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("权限设置暂时没有保存成功，请稍后再试。")
        }
    }

    private func save() {
        guard let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        let visStr = visibility == .link ? "LINK" : "PRIVATE"
        let vis = visibility
        let hug = hugEnabled
        isSaving = true
        Task { @MainActor in
            do {
                try await APIClient.shared.updateShare(token: token, petId: petId,
                                                       visibility: visStr, hugEnabled: hug)
                appState.share?.visibility = vis
                appState.share?.hugEnabled = hug
            } catch {
                print("updateShare error: \(error)")
                saveError = true
            }
            isSaving = false
        }
    }
}
