import SwiftUI

// MARK: - Main View

struct OnboardingStartView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @State private var navigateToLogin = false
    @State private var navigateToPetInfo = false

    var onSkip: (() -> Void)? = nil

    private var s: Strings { ls.strings }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    OnboardingHeroIllustration()

                    VStack(spacing: 0) {
                        Text(s.onboardingTitle)
                            .font(AppFonts.serif(28, weight: .medium))
                            .foregroundStyle(AppColors.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundStyle(AppColors.gold.opacity(0.55))
                                    .offset(x: 16, y: -3)
                            }
                            .padding(.top, 30)

                        Text(s.onboardingBody)
                            .font(AppFonts.body(15))
                            .foregroundStyle(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 14)

                        HStack(spacing: 0) {
                            OnboardingFeaturePoint(
                                icon: "photo.badge.plus",
                                label: s.onboardingFeature1,
                                iconColor: AppColors.rose.opacity(0.75),
                                iconBg: AppColors.rose.opacity(0.10)
                            )
                            Rectangle()
                                .fill(AppColors.line.opacity(0.55))
                                .frame(width: 1, height: 28)
                            OnboardingFeaturePoint(
                                icon: "heart.text.square.fill",
                                label: s.onboardingFeature2,
                                iconColor: AppColors.greenDeep.opacity(0.65),
                                iconBg: AppColors.green.opacity(0.10)
                            )
                            Rectangle()
                                .fill(AppColors.line.opacity(0.55))
                                .frame(width: 1, height: 28)
                            OnboardingFeaturePoint(
                                icon: "paperplane.fill",
                                label: s.onboardingFeature3,
                                iconColor: AppColors.gold.opacity(0.80),
                                iconBg: AppColors.gold.opacity(0.10)
                            )
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
                            Text(s.startCreate)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundStyle(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.greenDeep.opacity(0.86))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AppColors.greenDeep.opacity(0.10), radius: 8, x: 0, y: 3)
                        }

                        Button(s.laterBtn) {
                            if let onSkip = onSkip { onSkip() } else { dismiss() }
                        }
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.muted)

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
                            .foregroundStyle(AppColors.muted.opacity(0.55))
                            Button("🧪 Mock数据 → 直接进主界面") {
                                appState.loadMockData()
                            }
                            .font(AppFonts.body(11))
                            .foregroundStyle(AppColors.muted.opacity(0.55))
                        }
                        #endif
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToLogin) { LoginView() }
            .navigationDestination(isPresented: $navigateToPetInfo) { PetInfoView() }
        }
    }
}

// MARK: - Hero Illustration

private struct OnboardingHeroIllustration: View {
    @State private var haloBreathing = false
    @State private var leafSwaying   = false

    var body: some View {
        ZStack {
            // Outermost halo — slow breathing scale
            Circle()
                .fill(AppColors.green.opacity(0.03))
                .frame(width: 308, height: 308)
                .scaleEffect(haloBreathing ? 1.025 : 1.0)
                .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: haloBreathing)
            Circle()
                .fill(AppColors.green.opacity(0.055))
                .frame(width: 278, height: 278)
            Circle()
                .fill(AppColors.green.opacity(0.04))
                .frame(width: 256, height: 256)

            // Leaf branches — gentle sway, left/right on different timing
            PlanetLeafCluster(mirrored: false)
                .offset(x: 90, y: -118)
                .rotationEffect(.degrees(leafSwaying ? 2.5 : -0.5), anchor: UnitPoint(x: 0.5, y: 1.0))
                .animation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true), value: leafSwaying)
            PlanetLeafCluster(mirrored: true)
                .offset(x: -90, y: -118)
                .rotationEffect(.degrees(leafSwaying ? -2.5 : 0.5), anchor: UnitPoint(x: 0.5, y: 1.0))
                .animation(.easeInOut(duration: 4.3).repeatForever(autoreverses: true), value: leafSwaying)

            // Planet image
            Image("onboarding_planet")
                .resizable()
                .scaledToFill()
                .frame(width: 244, height: 244)
                .clipShape(Circle())

            // Rim gradient stroke
            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.90), location: 0.00),
                            .init(color: AppColors.green.opacity(0.18), location: 0.28),
                            .init(color: Color.white.opacity(0.20), location: 0.60),
                            .init(color: AppColors.green.opacity(0.08), location: 1.00),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 244, height: 244)
        }
        .frame(width: 320, height: 312)
        .shadow(color: Color.black.opacity(0.05), radius: 28, x: 0, y: 10)
        .onAppear {
            haloBreathing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { leafSwaying = true }
        }
    }
}

// MARK: - Leaf Decoration

private struct PlanetLeafCluster: View {
    let mirrored: Bool

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .fill(AppColors.green.opacity(0.22 - Double(i) * 0.025))
                    .frame(width: 16 - CGFloat(i) * 1.2, height: 7)
                    .rotationEffect(.degrees(Double(i) * 22 - 14))
                    .offset(
                        x: CGFloat(i) * 8 - 5,
                        y: CGFloat(i) * -7 + 4
                    )
            }
            Ellipse()
                .fill(AppColors.green.opacity(0.12))
                .frame(width: 10, height: 5)
                .rotationEffect(.degrees(-48))
                .offset(x: -8, y: 10)
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}

// MARK: - Feature Point

private struct OnboardingFeaturePoint: View {
    let icon: String
    let label: String
    let iconColor: Color
    let iconBg: Color

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(iconBg)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                        .symbolRenderingMode(.hierarchical)
                )

            Text(label)
                .font(AppFonts.body(11))
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
