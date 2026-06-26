import SwiftUI

// MARK: - Main View

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
                    Spacer(minLength: 0)

                    OnboardingHeroIllustration()

                    VStack(spacing: 0) {
                        Text("为TA留下一颗星球")
                            .font(AppFonts.serif(28, weight: .medium))
                            .foregroundColor(AppColors.ink)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(AppColors.gold.opacity(0.55))
                                    .offset(x: 16, y: -3)
                            }
                            .padding(.top, 30)

                        Text("先留下TA的名字和一张照片，\n故事和回忆可以之后慢慢补充。")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.top, 14)

                        HStack(spacing: 0) {
                            OnboardingFeaturePoint(icon: "photo.fill",    label: "留下名字和照片")
                            Rectangle()
                                .fill(AppColors.line.opacity(0.55))
                                .frame(width: 1, height: 28)
                            OnboardingFeaturePoint(icon: "note.text",     label: "慢慢补充回忆")
                            Rectangle()
                                .fill(AppColors.line.opacity(0.55))
                                .frame(width: 1, height: 28)
                            OnboardingFeaturePoint(icon: "person.2.fill", label: "分享给记得TA的人")
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 32)

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
                                .background(AppColors.greenDeep.opacity(0.86))
                                .cornerRadius(14)
                                .shadow(color: AppColors.greenDeep.opacity(0.10), radius: 8, x: 0, y: 3)
                        }

                        Button("稍后再说") {
                            if let onSkip = onSkip { onSkip() } else { dismiss() }
                        }
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)

                        #if DEBUG
                        VStack(spacing: 6) {
                            Divider().opacity(0.4).padding(.vertical, 4)
                            Button("🧪 真实API登录 → 创建流程") {
                                Task { @MainActor in
                                    await appState.debugLoginAndStart()
                                    if appState.ownerStage == .loggedInNoPet {
                                        navigateToPetInfo = true
                                    }
                                }
                            }
                            .font(AppFonts.body(11))
                            .foregroundColor(AppColors.muted.opacity(0.55))
                            Button("🧪 Mock数据 → 直接进主界面") {
                                appState.loadMockData()
                            }
                            .font(AppFonts.body(11))
                            .foregroundColor(AppColors.muted.opacity(0.55))
                        }
                        #endif
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLogin) { LoginView() }
            .navigationDestination(isPresented: $navigateToPetInfo) { PetInfoView() }
        }
    }
}

// MARK: - Hero Illustration

private struct OnboardingHeroIllustration: View {
    var body: some View {
        ZStack {
            // Single soft outer halo
            Circle()
                .fill(AppColors.green.opacity(0.05))
                .frame(width: 272, height: 272)

            // Leaf branches — very subtle, behind the circle
            PlanetLeafCluster(mirrored: false)
                .offset(x: 88, y: -110)
            PlanetLeafCluster(mirrored: true)
                .offset(x: -88, y: -110)

            // Scene clipped to circle
            ZStack {
                PlanetSkyView()
                PlanetStarField()
                PlanetClouds()
                PlanetHills()
                PlanetPets()
            }
            .frame(width: 232, height: 232)
            .clipShape(Circle())

            // Rim light — light and natural, not heavy
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            AppColors.green.opacity(0.10),
                            Color.white.opacity(0.22),
                            AppColors.green.opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 232, height: 232)
        }
        .frame(width: 320, height: 308)
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Scene Layers

private struct PlanetSkyView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.95, blue: 0.96),
                Color(red: 0.87, green: 0.93, blue: 0.91),
                Color(red: 0.77, green: 0.86, blue: 0.80),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct PlanetStarField: View {
    var body: some View {
        ZStack {
            // Single elegant star — the focal point of the sky
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .ultraLight))
                .foregroundColor(Color.white.opacity(0.92))
                .offset(x: 8, y: -54)

            // A few very subtle dot stars
            Circle().fill(Color.white.opacity(0.52)).frame(width: 3,   height: 3).offset(x: -44, y: -64)
            Circle().fill(Color.white.opacity(0.38)).frame(width: 2.5, height: 2.5).offset(x: 54,  y: -56)
            Circle().fill(Color.white.opacity(0.28)).frame(width: 2,   height: 2).offset(x: -62, y: -42)
        }
    }
}

private struct PlanetClouds: View {
    var body: some View {
        ZStack {
            PuffCloud(scale: 0.68).offset(x: -52, y: -22).opacity(0.80)
            PuffCloud(scale: 0.46).offset(x: 60,  y: -13).opacity(0.58)
        }
    }
}

private struct PuffCloud: View {
    let scale: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.38)).frame(width: 40, height: 40).offset(x: -10, y: 6)
            Circle().fill(Color.white.opacity(0.46)).frame(width: 52, height: 52)
            Circle().fill(Color.white.opacity(0.38)).frame(width: 36, height: 36).offset(x: 18, y: 7)
            Circle().fill(Color.white.opacity(0.32)).frame(width: 28, height: 28).offset(x: -26, y: 10)
        }
        .scaleEffect(scale)
    }
}

private struct PlanetHills: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Far hill — lighter, more distant
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.63))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.60),
                        control1: CGPoint(x: w * 0.28, y: h * 0.42),
                        control2: CGPoint(x: w * 0.68, y: h * 0.70)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.64, green: 0.76, blue: 0.60).opacity(0.50))

                // Main hill — lush green
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.77))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.74),
                        control1: CGPoint(x: w * 0.30, y: h * 0.57),
                        control2: CGPoint(x: w * 0.72, y: h * 0.82)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.50, green: 0.64, blue: 0.45).opacity(0.70))

                // Ground strip — darkest green at base
                Path { p in
                    p.addRect(CGRect(x: 0, y: h * 0.88, width: w, height: h * 0.12))
                }
                .fill(Color(red: 0.42, green: 0.56, blue: 0.36).opacity(0.62))
            }
        }
    }
}

private struct PlanetPets: View {
    var body: some View {
        ZStack {
            // Dog (left — warm dark brown, floppy ears)
            PlanetDogShape()
                .fill(Color(red: 0.56, green: 0.51, blue: 0.44).opacity(0.92))
                .frame(width: 52, height: 56)
                .offset(x: -22, y: 28)

            // Cat (right — darker grey, pointed ears)
            PlanetCatShape()
                .fill(Color(red: 0.38, green: 0.36, blue: 0.33).opacity(0.88))
                .frame(width: 36, height: 44)
                .offset(x: 22, y: 34)
        }
    }
}

private struct PlanetDogShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height

        // Body
        p.addRoundedRect(
            in: CGRect(x: w*0.12, y: h*0.46, width: w*0.76, height: h*0.48),
            cornerSize: CGSize(width: 10, height: 10)
        )

        // Head
        p.addEllipse(in: CGRect(x: w*0.20, y: h*0.10, width: w*0.60, height: h*0.46))

        // Left floppy ear — organic bezier curve
        p.move(to: CGPoint(x: w*0.24, y: h*0.24))
        p.addCurve(
            to: CGPoint(x: w*0.06, y: h*0.56),
            control1: CGPoint(x: w*0.00, y: h*0.28),
            control2: CGPoint(x: w*0.04, y: h*0.46)
        )
        p.addCurve(
            to: CGPoint(x: w*0.22, y: h*0.54),
            control1: CGPoint(x: w*0.08, y: h*0.64),
            control2: CGPoint(x: w*0.16, y: h*0.62)
        )
        p.addCurve(
            to: CGPoint(x: w*0.24, y: h*0.24),
            control1: CGPoint(x: w*0.28, y: h*0.42),
            control2: CGPoint(x: w*0.28, y: h*0.32)
        )

        // Right floppy ear (mirrored)
        p.move(to: CGPoint(x: w*0.76, y: h*0.24))
        p.addCurve(
            to: CGPoint(x: w*0.94, y: h*0.56),
            control1: CGPoint(x: w*1.00, y: h*0.28),
            control2: CGPoint(x: w*0.96, y: h*0.46)
        )
        p.addCurve(
            to: CGPoint(x: w*0.78, y: h*0.54),
            control1: CGPoint(x: w*0.92, y: h*0.64),
            control2: CGPoint(x: w*0.84, y: h*0.62)
        )
        p.addCurve(
            to: CGPoint(x: w*0.76, y: h*0.24),
            control1: CGPoint(x: w*0.72, y: h*0.42),
            control2: CGPoint(x: w*0.72, y: h*0.32)
        )

        return p
    }
}

private struct PlanetCatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height

        // Body
        p.addRoundedRect(
            in: CGRect(x: w*0.10, y: h*0.50, width: w*0.80, height: h*0.42),
            cornerSize: CGSize(width: 8, height: 8)
        )

        // Head — slightly taller than wide
        p.addEllipse(in: CGRect(x: w*0.12, y: h*0.22, width: w*0.76, height: h*0.36))

        // Left ear — curved triangle
        p.move(to: CGPoint(x: w*0.18, y: h*0.28))
        p.addCurve(
            to: CGPoint(x: w*0.08, y: h*0.05),
            control1: CGPoint(x: w*0.10, y: h*0.20),
            control2: CGPoint(x: w*0.06, y: h*0.12)
        )
        p.addCurve(
            to: CGPoint(x: w*0.40, y: h*0.24),
            control1: CGPoint(x: w*0.24, y: h*0.04),
            control2: CGPoint(x: w*0.34, y: h*0.16)
        )
        p.closeSubpath()

        // Right ear (mirrored)
        p.move(to: CGPoint(x: w*0.82, y: h*0.28))
        p.addCurve(
            to: CGPoint(x: w*0.92, y: h*0.05),
            control1: CGPoint(x: w*0.90, y: h*0.20),
            control2: CGPoint(x: w*0.94, y: h*0.12)
        )
        p.addCurve(
            to: CGPoint(x: w*0.60, y: h*0.24),
            control1: CGPoint(x: w*0.76, y: h*0.04),
            control2: CGPoint(x: w*0.66, y: h*0.16)
        )
        p.closeSubpath()

        return p
    }
}

// MARK: - Leaf Decoration

private struct PlanetLeafCluster: View {
    let mirrored: Bool

    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                Ellipse()
                    .fill(AppColors.green.opacity(0.20 - Double(i) * 0.03))
                    .frame(width: 14, height: 7)
                    .rotationEffect(.degrees(Double(i) * 22 - 12))
                    .offset(x: CGFloat(i) * 7 - 4, y: CGFloat(i) * -6 + 4)
            }
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}

// MARK: - Feature Point

private struct OnboardingFeaturePoint: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(AppColors.green.opacity(0.08))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.greenDeep.opacity(0.58))
                )

            Text(label)
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
