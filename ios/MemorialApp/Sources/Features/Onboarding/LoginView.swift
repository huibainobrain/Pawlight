import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToPetInfo = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.green)
                    VStack(spacing: 8) {
                        Text("登录以保存TA的星球")
                            .font(AppFonts.serif(22, weight: .medium))
                            .foregroundColor(AppColors.ink)
                        Text("账号让你可以随时回来，也让权益和\n纪念内容长期绑定。")
                            .font(AppFonts.body(14))
                            .foregroundColor(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                Spacer()
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    if let error = errorMessage {
                        Text(error)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.rose)
                            .multilineTextAlignment(.center)
                    }

                    Text("继续即表示同意《用户协议》和《隐私政策》")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)

                    #if DEBUG
                    VStack(spacing: 8) {
                        Button("跳过登录 → 创建流程（真实API）") {
                            Task { @MainActor in
                                await appState.debugLoginAndStart()
                                if appState.ownerStage == .loggedInNoPet {
                                    navigateToPetInfo = true
                                }
                            }
                        }
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted.opacity(0.5))

                        Button("跳过登录 → 直接进主界面（Mock）") {
                            appState.loadMockData()
                        }
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted.opacity(0.5))
                    }
                    #endif
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPetInfo) {
            PetInfoView()
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "无法获取登录凭证"
                return
            }
            Task { @MainActor in
                do {
                    try await appState.login(identityToken: identityToken)
                    if appState.ownerStage == .loggedInNoPet {
                        navigateToPetInfo = true
                    }
                    // hasPetFree/hasPetPaid: RootView auto-switches to MainTabView
                } catch {
                    errorMessage = "登录遇到问题，请再试一次"
                    print("Login error: \(error)")
                }
            }
        case .failure(let error):
            errorMessage = "登录遇到问题，请再试一次"
            print("Apple Sign In error: \(error)")
        }
    }
}
