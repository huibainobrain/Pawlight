import SwiftUI

struct MailboxLockedView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ls: LanguageStore
    @State private var showEntitlement = false

    private var s: Strings { ls.strings }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // 信封插画
                envelopeIllustration
                    .padding(.top, 24)

                // 标题与说明
                VStack(spacing: 12) {
                    Text(s.mailboxLockedTitle)
                        .font(AppFonts.serif(26, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                    Text(s.mailboxLockedBody)
                        .font(AppFonts.body(15))
                        .foregroundStyle(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)

                // 私密边界提示卡
                privacyHintCard
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                // 完整纪念空间包含 说明卡
                entitlementCard
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                // 按钮区
                VStack(spacing: 14) {
                    Button { showEntitlement = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.white.opacity(0.85))
                            Text(s.mailboxLockedLearnMoreBtn)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundStyle(AppColors.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.greenDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(s.laterBtn) { dismiss() }
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.muted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 52)
            }
        }
        .background(AppColors.paper.ignoresSafeArea())
        .navigationTitle(s.mailboxLockedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .padding(8)
                        .background(AppColors.white.opacity(0.88))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showEntitlement) {
            EntitlementView()
        }
    }

    // MARK: - 信封插画

    private var envelopeIllustration: some View {
        ZStack {
            // 外光晕
            Circle()
                .fill(AppColors.gold.opacity(0.06))
                .frame(width: 180)
            // 奶白圆形底
            Circle()
                .fill(Color(red: 0.97, green: 0.95, blue: 0.91))
                .frame(width: 148)

            // 信封主体
            Image(systemName: "envelope.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(red: 0.88, green: 0.82, blue: 0.66))

            // 心形封蜡
            Image(systemName: "heart.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.gold.opacity(0.72))
                .offset(y: 4)

            // 左下叶片
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.green.opacity(0.44))
                .rotationEffect(.degrees(-42))
                .offset(x: -44, y: 24)
            Image(systemName: "leaf.fill")
                .font(.system(size: 9))
                .foregroundStyle(AppColors.green.opacity(0.30))
                .rotationEffect(.degrees(-62))
                .offset(x: -56, y: 33)

            // 右下叶片
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.green.opacity(0.44))
                .rotationEffect(.degrees(138))
                .offset(x: 44, y: 24)
            Image(systemName: "leaf.fill")
                .font(.system(size: 9))
                .foregroundStyle(AppColors.green.opacity(0.30))
                .rotationEffect(.degrees(118))
                .offset(x: 56, y: 33)

            // 星光点缀
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundStyle(AppColors.muted.opacity(0.25))
                .offset(x: 54, y: -28)
            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .ultraLight))
                .foregroundStyle(AppColors.muted.opacity(0.18))
                .offset(x: -48, y: -32)
            Circle()
                .fill(AppColors.gold.opacity(0.28))
                .frame(width: 4)
                .offset(x: 42, y: -44)
            Circle()
                .fill(AppColors.muted.opacity(0.18))
                .frame(width: 3)
                .offset(x: -36, y: -42)
        }
        .frame(height: 170)
    }

    // MARK: - 私密边界提示卡

    private var privacyHintCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.muted.opacity(0.55))
                .padding(.top, 1)
            Text(s.mailboxLockedPrivacyHint)
                .font(AppFonts.body(13))
                .foregroundStyle(AppColors.muted.opacity(0.68))
                .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.muted.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 完整纪念空间包含 说明卡

    private var entitlementCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(s.mailboxLockedEntitlementTitle)
                .font(AppFonts.body(13, weight: .medium))
                .foregroundStyle(AppColors.ink.opacity(0.72))
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            EntitlementItemRow(
                icon: "envelope.fill",
                iconColor: AppColors.green.opacity(0.65),
                title: s.mailboxLockedMailboxTitle,
                subtitle: s.mailboxLockedMailboxSubtitle
            )

            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5)
                .padding(.leading, 60)

            EntitlementItemRow(
                icon: "photo.on.rectangle.fill",
                iconColor: AppColors.green.opacity(0.65),
                title: s.mailboxLockedPhotosTitle,
                subtitle: s.mailboxLockedPhotosSubtitle
            )

            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5)
                .padding(.leading, 60)

            EntitlementItemRow(
                icon: "star",
                iconColor: AppColors.green.opacity(0.65),
                title: s.mailboxLockedMoreTitle,
                subtitle: s.mailboxLockedMoreSubtitle
            )
        }
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.line, lineWidth: 1))
    }
}

// MARK: - 权益条目行

private struct EntitlementItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.green.opacity(0.10))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundStyle(AppColors.ink)
                Text(subtitle)
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
