import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var visibility: Share.Visibility = .link
    @State private var hugEnabled = true

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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    appState.share?.visibility = visibility
                    appState.share?.hugEnabled = hugEnabled
                    guard let token = KeychainHelper.loadToken(),
                          let petId = appState.currentPet?.id else { return }
                    let visStr = visibility == .link ? "LINK" : "PRIVATE"
                    let enabled = hugEnabled
                    Task {
                        try? await APIClient.shared.updateShare(token: token, petId: petId,
                                                                 visibility: visStr, hugEnabled: enabled)
                    }
                }
                .foregroundColor(AppColors.greenDeep)
                .fontWeight(.medium)
            }
        }
        .onAppear {
            visibility = appState.share?.visibility ?? .link
            hugEnabled = appState.share?.hugEnabled ?? true
        }
    }
}
