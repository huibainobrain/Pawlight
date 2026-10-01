import SwiftUI

// One-time introduction shown the first time the user taps "陪我一会儿",
// before CompanionWindowPiPController.hasSeenIntro is true. Structure
// mirrors HomeView.swift's LearnMoreSheet: AppColors.paper background,
// .medium detent, system drag indicator (no custom one).
struct CompanionWindowIntroSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ls: LanguageStore
    let onStart: () -> Void

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 24) {
            Text(s.companionWindowIntroTitle)
                .font(AppFonts.serif(18, weight: .medium))
                .foregroundColor(AppColors.ink)
                .multilineTextAlignment(.center)

            Text(s.companionWindowIntroBody)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.muted)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
                onStart()
            } label: {
                Text(s.companionWindowIntroStartBtn)
                    .font(AppFonts.body(15, weight: .medium))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.greenDeep)
                    .cornerRadius(12)
            }

            Button {
                dismiss()
            } label: {
                Text(s.companionWindowIntroLaterBtn)
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .background(AppColors.paper.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
