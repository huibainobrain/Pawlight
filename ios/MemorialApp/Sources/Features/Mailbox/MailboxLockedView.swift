import SwiftUI

struct MailboxLockedView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showEntitlement = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "envelope")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.gold.opacity(0.75))
                    }
                    VStack(spacing: 14) {
                        Text("天堂信箱")
                            .font(AppFonts.serif(22, weight: .medium))
                            .foregroundColor(AppColors.ink)
                        Text("有些话，不一定要放在纪念页里。\n开启后，可以把想对TA说的话慢慢写在这里，只有你自己可以看到。")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.horizontal, 8)
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.muted.opacity(0.5))
                                .padding(.top, 1)
                            Text("这些信不会展示在分享出去的纪念页中，也不会被访客看到。")
                                .font(AppFonts.body(12))
                                .foregroundColor(AppColors.muted.opacity(0.5))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    }
                }
                Spacer()
                VStack(spacing: 14) {
                    Button { showEntitlement = true } label: {
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
        .navigationDestination(isPresented: $showEntitlement) {
            EntitlementView()
        }
    }
}
