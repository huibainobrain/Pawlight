import SwiftUI

struct OnboardingStartView: View {
    @EnvironmentObject var appState: AppState
    @State private var goToLogin = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 32) {
                        ZStack {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(AppColors.green.opacity(0.06 - Double(i) * 0.015))
                                    .frame(width: CGFloat(180 + i * 40), height: CGFloat(180 + i * 40))
                            }
                            Image(systemName: "sparkle")
                                .font(.system(size: 56))
                                .foregroundColor(AppColors.green)
                        }
                        VStack(spacing: 14) {
                            Text("为TA留下一颗星球")
                                .font(AppFonts.serif(26, weight: .medium))
                                .foregroundColor(AppColors.ink)
                            Text("温柔地记住TA，\n在想TA的时候，回来看看。")
                                .font(AppFonts.body(16))
                                .foregroundColor(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    Spacer()
                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("开始创建")
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.greenDeep)
                                .cornerRadius(12)
                        }
                        Button("稍后再说") {
                            dismiss()
                        }
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
