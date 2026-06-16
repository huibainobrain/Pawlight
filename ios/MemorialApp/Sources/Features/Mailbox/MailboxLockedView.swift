import SwiftUI

struct MailboxLockedView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.gold)
                    }
                    VStack(spacing: 12) {
                        Text("天堂信箱")
                            .font(AppFonts.serif(22, weight: .medium))
                            .foregroundColor(AppColors.ink)
                        Text("想说的话，慢慢写在这里，\n只有你自己可以看到。")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        Text("开启完整纪念空间后可用")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                            .padding(.top, 4)
                    }
                }
                Spacer()
                VStack(spacing: 14) {
                    Button {} label: {
                        Text("了解完整纪念空间")
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.greenDeep)
                            .cornerRadius(12)
                    }
                    Button("稍后再说") { dismiss() }
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
        .navigationTitle("天堂信箱")
        .navigationBarTitleDisplayMode(.inline)
    }
}
