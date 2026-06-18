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
                StepIndicator(current: 0, total: 3)
                    .padding(.top, 16)

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
                        Button("跳过登录 → 创建流程") {
                            appState.currentUser = User(
                                id: "usr_debug",
                                loginStatus: .loggedIn,
                                loginProvider: "debug",
                                nickname: nil,
                                avatarURL: nil,
                                createdAt: Date()
                            )
                            appState.ownerStage = .loggedInNoPet
                            navigateToPetInfo = true
                        }
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted.opacity(0.5))

                        Button("跳过登录 → 直接进主界面") {
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
            guard auth.credential is ASAuthorizationAppleIDCredential else { return }
            // TODO: send identity_token to backend /api/v1/auth/login
            // For now, simulate login success
            appState.currentUser = User(
                id: "usr_mock",
                loginStatus: .loggedIn,
                loginProvider: "apple",
                nickname: nil,
                avatarURL: nil,
                createdAt: Date()
            )
            appState.ownerStage = .loggedInNoPet
            navigateToPetInfo = true
        case .failure(let error):
            errorMessage = "登录遇到问题，请再试一次"
            print("Apple Sign In error: \(error)")
        }
    }
}
