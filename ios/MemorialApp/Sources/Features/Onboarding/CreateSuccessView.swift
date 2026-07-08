import SwiftUI

struct CreateSuccessView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 36)

                SuccessPlanetView()

                Spacer(minLength: 28)

                VStack(spacing: 14) {
                    Text(s.successTitle)
                        .font(AppFonts.serif(26, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)

                    Text(appState.isPaid ? s.successBodyPaid : s.successBodyFree)
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 36)

                Spacer()

                VStack(spacing: 12) {
                    // 主按钮：继续补充回忆
                    Button {
                        appState.selectedTab = 1
                        Task { await appState.loadCurrentPet() }
                    } label: {
                        Text(s.successContinueBtn)
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.greenDeep.opacity(0.86))
                            .cornerRadius(14)
                            .shadow(color: AppColors.greenDeep.opacity(0.10), radius: 8, x: 0, y: 3)
                    }

                    // 次按钮：去看看TA
                    Button {
                        appState.selectedTab = 0
                        Task { await appState.loadCurrentPet() }
                    } label: {
                        Text(s.successViewBtn)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.greenDeep.opacity(0.68))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.greenDeep.opacity(0.22), lineWidth: 1.2)
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 星球主视觉

private struct SuccessPlanetView: View {
    var body: some View {
        ZStack {
            // 背景星点
            Group {
                Circle().fill(AppColors.muted.opacity(0.16)).frame(width: 3).offset(x: -102, y: -72)
                Circle().fill(AppColors.muted.opacity(0.12)).frame(width: 2).offset(x: 112, y: -52)
                Circle().fill(AppColors.muted.opacity(0.20)).frame(width: 2.5).offset(x: -122, y: 32)
                Circle().fill(AppColors.muted.opacity(0.14)).frame(width: 2).offset(x: 98, y: 82)
                Circle().fill(AppColors.muted.opacity(0.17)).frame(width: 3).offset(x: -62, y: -108)
                Circle().fill(AppColors.muted.opacity(0.10)).frame(width: 2).offset(x: 72, y: -96)
            }

            // 外光晕
            Circle()
                .fill(AppColors.green.opacity(0.038))
                .frame(width: 304, height: 304)
            Circle()
                .fill(AppColors.green.opacity(0.054))
                .frame(width: 264, height: 264)

            // 轨道环
            Ellipse()
                .stroke(AppColors.muted.opacity(0.22), lineWidth: 1.0)
                .frame(width: 298, height: 72)
                .rotationEffect(.degrees(-15))

            // 轨道小卫星
            Circle()
                .fill(AppColors.muted.opacity(0.26))
                .frame(width: 9, height: 9)
                .offset(x: 144, y: 25)

            // 左侧叶片
            ZStack {
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.24))
                    .frame(width: 22, height: 38)
                    .rotationEffect(.degrees(-28))
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.17))
                    .frame(width: 16, height: 28)
                    .rotationEffect(.degrees(-50))
                    .offset(x: -8, y: 12)
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.12))
                    .frame(width: 12, height: 20)
                    .rotationEffect(.degrees(-6))
                    .offset(x: 10, y: 10)
            }
            .offset(x: -153, y: -30)

            // 右侧叶片
            ZStack {
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.20))
                    .frame(width: 20, height: 34)
                    .rotationEffect(.degrees(42))
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.14))
                    .frame(width: 15, height: 26)
                    .rotationEffect(.degrees(64))
                    .offset(x: 8, y: 12)
                SuccessLeaf()
                    .fill(AppColors.green.opacity(0.09))
                    .frame(width: 11, height: 18)
                    .rotationEffect(.degrees(22))
                    .offset(x: -8, y: 16)
            }
            .offset(x: 152, y: 64)

            // 星球主体（裁剪为圆形）
            ZStack {
                // 主渐变
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.95, blue: 0.91),
                                Color(red: 0.84, green: 0.89, blue: 0.81),
                                Color(red: 0.74, green: 0.82, blue: 0.70),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 228, height: 228)

                // 远山
                SuccessMountainShape(layer: 0)
                    .fill(Color(red: 0.64, green: 0.76, blue: 0.60).opacity(0.42))
                    .frame(width: 228, height: 228)

                // 近山丘
                SuccessMountainShape(layer: 1)
                    .fill(Color(red: 0.50, green: 0.67, blue: 0.46).opacity(0.50))
                    .frame(width: 228, height: 228)

                // 地平线云雾
                Ellipse()
                    .fill(.white.opacity(0.55))
                    .frame(width: 152, height: 38)
                    .blur(radius: 14)
                    .offset(y: 26)

                // 中央大星光
                Image(systemName: "sparkle")
                    .font(.system(size: 34, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.90))
                    .offset(x: 6, y: 16)

                // 上方中星光
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.78))
                    .offset(x: -32, y: -34)

                // 小星光
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.62))
                    .offset(x: 44, y: -52)

                // 小点缀
                Circle()
                    .fill(.white.opacity(0.50))
                    .frame(width: 4, height: 4)
                    .offset(x: -50, y: 10)
            }
            .frame(width: 228, height: 228)
            .clipShape(Circle())

            // 星球边框
            Circle()
                .stroke(AppColors.green.opacity(0.15), lineWidth: 1.0)
                .frame(width: 228, height: 228)
        }
        .frame(width: 320, height: 320)
    }
}

// MARK: - 山丘形状

private struct SuccessMountainShape: Shape {
    let layer: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        if layer == 0 {
            p.move(to: CGPoint(x: 0, y: h * 0.73))
            p.addCurve(
                to: CGPoint(x: w * 0.36, y: h * 0.55),
                control1: CGPoint(x: w * 0.12, y: h * 0.73),
                control2: CGPoint(x: w * 0.24, y: h * 0.55)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.57, y: h * 0.63),
                control1: CGPoint(x: w * 0.48, y: h * 0.55),
                control2: CGPoint(x: w * 0.57, y: h * 0.63)
            )
            p.addCurve(
                to: CGPoint(x: w, y: h * 0.58),
                control1: CGPoint(x: w * 0.74, y: h * 0.63),
                control2: CGPoint(x: w * 0.86, y: h * 0.52)
            )
        } else {
            p.move(to: CGPoint(x: 0, y: h * 0.82))
            p.addCurve(
                to: CGPoint(x: w * 0.38, y: h * 0.69),
                control1: CGPoint(x: w * 0.14, y: h * 0.82),
                control2: CGPoint(x: w * 0.26, y: h * 0.69)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.60, y: h * 0.76),
                control1: CGPoint(x: w * 0.50, y: h * 0.69),
                control2: CGPoint(x: w * 0.60, y: h * 0.76)
            )
            p.addCurve(
                to: CGPoint(x: w, y: h * 0.73),
                control1: CGPoint(x: w * 0.76, y: h * 0.76),
                control2: CGPoint(x: w * 0.88, y: h * 0.67)
            )
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: - 叶片形状

private struct SuccessLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.5, y: 0))
            p.addCurve(
                to: CGPoint(x: w * 0.5, y: h),
                control1: CGPoint(x: w, y: h * 0.25),
                control2: CGPoint(x: w, y: h * 0.75)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.5, y: 0),
                control1: CGPoint(x: 0, y: h * 0.75),
                control2: CGPoint(x: 0, y: h * 0.25)
            )
        }
    }
}
