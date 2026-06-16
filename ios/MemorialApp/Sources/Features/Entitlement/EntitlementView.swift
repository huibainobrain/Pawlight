import SwiftUI

struct EntitlementView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if appState.isPaid {
                        PaidBadgeView()
                            .padding(.top, 24)
                    } else {
                        Text("选择适合TA的纪念空间")
                            .font(AppFonts.serif(22, weight: .medium))
                            .foregroundColor(AppColors.ink)
                            .padding(.top, 24)
                    }

                    EntitlementCompareView()
                        .padding(.horizontal, 20)

                    if !appState.isPaid {
                        Button {} label: {
                            VStack(spacing: 4) {
                                Text("开启完整纪念空间")
                                    .font(AppFonts.body(16, weight: .medium))
                                    .foregroundColor(AppColors.white)
                                HStack(spacing: 8) {
                                    Text("¥29.9")
                                        .font(AppFonts.body(14, weight: .semibold))
                                        .foregroundColor(AppColors.white)
                                    Text("¥59.9")
                                        .font(AppFonts.body(12))
                                        .foregroundColor(AppColors.white.opacity(0.6))
                                        .strikethrough()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.greenDeep)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)

                        Button {} label: {
                            Text("恢复购买")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("纪念空间")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PaidBadgeView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.gold.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.gold)
            }
            Text("完整纪念空间已开启")
                .font(AppFonts.serif(20, weight: .medium))
                .foregroundColor(AppColors.ink)
        }
    }
}

struct EntitlementCompareView: View {
    var body: some View {
        VStack(spacing: 0) {
            EntitlementRow(feature: "主照片 + 首页星球观察窗", freeAvail: true, paidAvail: true)
            EntitlementRow(feature: "TA的故事", freeAvail: true, paidAvail: true)
            EntitlementRow(feature: "相册照片", freeDetail: "最多 9 张", paidDetail: "最多 50 张")
            EntitlementRow(feature: "H5 分享 + 访客抱抱", freeAvail: true, paidAvail: true)
            EntitlementRow(feature: "抱抱记录", freeAvail: true, paidAvail: true)
            EntitlementRow(feature: "天堂信箱", freeAvail: false, paidAvail: true)
        }
        .background(AppColors.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
    }
}

struct EntitlementRow: View {
    let feature: String
    var freeAvail: Bool = false
    var paidAvail: Bool = false
    var freeDetail: String? = nil
    var paidDetail: String? = nil

    var body: some View {
        HStack {
            Text(feature)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.ink)
            Spacer()
            HStack(spacing: 24) {
                Group {
                    if let d = freeDetail {
                        Text(d).font(AppFonts.body(12)).foregroundColor(AppColors.muted)
                    } else {
                        Image(systemName: freeAvail ? "checkmark" : "minus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(freeAvail ? AppColors.green : AppColors.muted)
                    }
                }
                .frame(width: 60, alignment: .center)

                Group {
                    if let d = paidDetail {
                        Text(d).font(AppFonts.body(12)).foregroundColor(AppColors.greenDeep)
                    } else {
                        Image(systemName: paidAvail ? "checkmark" : "minus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(paidAvail ? AppColors.green : AppColors.muted)
                    }
                }
                .frame(width: 60, alignment: .center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.horizontal, 16), alignment: .bottom)
    }
}
