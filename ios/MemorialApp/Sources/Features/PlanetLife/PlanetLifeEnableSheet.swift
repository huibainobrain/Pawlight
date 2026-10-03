import SwiftUI

// PRD §13 (explanation) chained into §14 (notification preference ask,
// asked only AFTER the user actively chooses to enable). One API call —
// enable(notifyOnNewEvent:) — fires once the user answers the second stage.
struct PlanetLifeEnableSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @Environment(\.dismiss) var dismiss

    private enum Stage { case explain, notifyAsk }
    @State private var stage: Stage = .explain
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var s: Strings { ls.strings }

    var body: some View {
        VStack(spacing: 22) {
            switch stage {
            case .explain: explainContent
            case .notifyAsk: notifyAskContent
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.rose)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isSubmitting)
    }

    private var explainContent: some View {
        VStack(spacing: 20) {
            // Production asset: same decorative photo-stack illustration as
            // the home intro card (see reference UI) — placeholder slot only.
            PlanetLifeIllustrationSlot(
                assetName: "planet_life_intro_photos",
                systemImageFallback: "photo.stack",
                size: 64
            )
            VStack(spacing: 10) {
                Text(s.planetLifeEnableExplainTitle)
                    .font(AppFonts.serif(18, weight: .medium))
                    .foregroundColor(AppColors.ink)
                    .multilineTextAlignment(.center)
                Text(s.planetLifeEnableExplainBody)
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            VStack(alignment: .leading, spacing: 10) {
                enableNote("sparkles", s.planetLifeEnableNoteAI)
                enableNote("clock", s.planetLifeEnableNoteNoSchedule)
                enableNote("pause.circle", s.planetLifeEnableNotePausable)
            }
            VStack(spacing: 12) {
                primaryButton(s.planetLifeEnableContinueBtn) { continueFromExplain() }
                Button(s.planetLifeEnableCancelBtn) { dismiss() }
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
            }
        }
    }

    // PlanetLifeCapabilities.pushNotificationsAvailable gates the notify-ask
    // stage (PRD §14's question) since Production must not ask a question it
    // can't act on while no real Push exists yet. notifyOnNewEvent is simply
    // submitted as false (an honest "not opted in to a capability the user
    // was never shown") — flipping the flag restores the stage with no
    // other change needed.
    private func continueFromExplain() {
        if PlanetLifeCapabilities.pushNotificationsAvailable {
            stage = .notifyAsk
        } else {
            Task { await submit(notify: false) }
        }
    }

    private var notifyAskContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(s.planetLifeNotifyAskTitle)
                    .font(AppFonts.serif(18, weight: .medium))
                    .foregroundColor(AppColors.ink)
                    .multilineTextAlignment(.center)
                Text(s.planetLifeNotifyAskBody)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 12) {
                primaryButton(s.planetLifeNotifyYesBtn) { Task { await submit(notify: true) } }
                Button(s.planetLifeNotifyNoBtn) { Task { await submit(notify: false) } }
                    .font(AppFonts.body(14))
                    .foregroundColor(AppColors.muted)
            }
        }
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.6 : 1)
    }

    private func enableNote(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppColors.green.opacity(0.6))
                .frame(width: 18)
            Text(text)
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.muted)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.greenDeep)
                .cornerRadius(12)
        }
    }

    private func submit(notify: Bool) async {
        guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
        isSubmitting = true
        errorMessage = nil
        let ok = await planetLife.enable(token: token, petId: petId, notifyOnNewEvent: notify)
        isSubmitting = false
        if ok {
            dismiss()
        } else {
            errorMessage = mapError(planetLife.lastErrorCode)
        }
    }

    private func mapError(_ code: String?) -> String {
        switch code {
        case "PAID_ONLY": return s.planetLifeErrorPaidOnly
        case "NO_SCENE_PORTRAIT_YET": return s.planetLifeErrorNoScenePortraitYet
        default: return s.planetLifeErrorGeneric
        }
    }
}
