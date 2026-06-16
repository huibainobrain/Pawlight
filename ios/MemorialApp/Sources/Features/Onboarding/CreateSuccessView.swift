import SwiftUI

struct CreateSuccessView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 32) {
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(AppColors.green.opacity(0.07 - Double(i) * 0.02))
                                .frame(width: CGFloat(160 + i * 50), height: CGFloat(160 + i * 50))
                        }
                        Image(systemName: "sparkles")
                            .font(.system(size: 56))
                            .foregroundColor(AppColors.green)
                    }
                    VStack(spacing: 12) {
                        Text("星球已经为TA准备好了")
                            .font(AppFonts.serif(24, weight: .medium))
                            .foregroundColor(AppColors.ink)
                        if appState.isPaid {
                            Text("完整纪念空间已开启，\n50 张相册和天堂信箱都在等TA。")
                                .font(AppFonts.body(15))
                                .foregroundColor(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        } else {
                            Text("补充一点回忆后，\n可以分享给也记得TA的人。")
                                .font(AppFonts.body(15))
                                .foregroundColor(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                }
                Spacer()
                VStack(spacing: 14) {
                    Button {
                        // Navigate to memory tab
                        appState.ownerStage = appState.isPaid ? .hasPetPaid : .hasPetFree
                    } label: {
                        Text("继续补充回忆")
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.greenDeep)
                            .cornerRadius(12)
                    }
                    Button {
                        appState.ownerStage = appState.isPaid ? .hasPetPaid : .hasPetFree
                    } label: {
                        Text("去看看TA")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.green)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
        .navigationBarHidden(true)
    }
}
