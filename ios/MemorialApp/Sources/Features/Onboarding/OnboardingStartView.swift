import SwiftUI

struct OnboardingStartView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var navigateToLogin = false
    @State private var navigateToPetInfo = false

    var onSkip: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 36) {
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
                        VStack(spacing: 16) {
                            Text("为TA留下一颗星球")
                                .font(AppFonts.serif(26, weight: .medium))
                                .foregroundColor(AppColors.ink)
                            Text("先留下TA的名字和一张照片，\n故事和回忆可以之后慢慢补充。")
                                .font(AppFonts.body(15))
                                .foregroundColor(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                            HStack(spacing: 20) {
                                FeaturePoint(icon: "pawprint.fill", label: "留下名字和照片")
                                FeaturePoint(icon: "text.quote", label: "慢慢补充回忆")
                                FeaturePoint(icon: "heart.fill", label: "分享给也记得TA的人")
                            }
                            .padding(.top, 4)
                        }
                    }
                    Spacer()
                    VStack(spacing: 16) {
                        Button {
                            if appState.isLoggedIn {
                                navigateToPetInfo = true
                            } else {
                                navigateToLogin = true
                            }
                        } label: {
                            Text("开始创建")
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.greenDeep)
                                .cornerRadius(12)
                        }
                        Button("稍后再说") {
                            if let onSkip = onSkip {
                                onSkip()
                            } else {
                                dismiss()
                            }
                        }
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $navigateToPetInfo) {
                PetInfoView()
            }
        }
    }
}

private struct FeaturePoint: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.green)
            Text(label)
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
    }
}
