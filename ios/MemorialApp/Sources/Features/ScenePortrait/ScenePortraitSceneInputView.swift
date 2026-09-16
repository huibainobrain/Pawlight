import SwiftUI

// Real counterpart to PromoDemo.swift's private PromoSceneInputView — same
// visual template, wired to the real ScenePortraitController/backend instead
// of a fixed countdown.
struct ScenePortraitSceneInputView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scenePortrait: ScenePortraitController
    @EnvironmentObject var ls: LanguageStore
    @State private var text = ""
    @FocusState private var focused: Bool

    private var s: Strings { ls.strings }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
                .onTapGesture { scenePortrait.cancelSceneInput() }

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(s.scenePortraitInputTitle)
                        .font(AppFonts.serif(20, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                    Text(s.scenePortraitInputBody)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                }

                TextField(s.scenePortraitInputPlaceholder, text: $text, axis: .vertical)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                    .lineLimit(3, reservesSpace: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppColors.paperSoft)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
                    .focused($focused)

                Button {
                    focused = false
                    submit()
                } label: {
                    Text(s.scenePortraitGenerateBtn)
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppColors.greenDeep.opacity(trimmed.isEmpty ? 0.5 : 0.9))
                        .cornerRadius(13)
                }
                .disabled(trimmed.isEmpty)
            }
            .padding(22)
            .background(AppColors.paper)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true }
        }
    }

    private func submit() {
        guard let token = KeychainHelper.loadToken(), let petId = appState.currentPet?.id else { return }
        let scene = trimmed
        Task {
            await scenePortrait.submitScene(token: token, petId: petId, sceneText: scene) {
                Task { await appState.loadCurrentPet() }
            }
        }
    }
}
