import SwiftUI

// Real counterpart to PromoDemo.swift's private PromoCandidatePickerView.
// Cells are boxed to a 1:1 ratio (the backend requests square candidates —
// see backend/src/scene-portraits/scene-portraits.constants.ts IMAGE_SIZE —
// chosen to fit the circular observation window's bounding box), using the
// same "Color.clear.aspectRatio(...).overlay(image)" trick so nothing crops
// unexpectedly if that ever changes.
struct ScenePortraitCandidatePickerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scenePortrait: ScenePortraitController
    @EnvironmentObject var ls: LanguageStore
    let candidates: [ScenePortraitController.Candidate]

    private var s: Strings { ls.strings }
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(s.scenePortraitPickTitle)
                        .font(AppFonts.serif(20, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text(s.scenePortraitPickBody)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(candidates) { candidate in
                        Button { pick(candidate) } label: {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    AsyncImage(url: URL(string: candidate.url)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        default:
                                            AppColors.paperSoft
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppColors.line, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(AppColors.paper)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    private func pick(_ candidate: ScenePortraitController.Candidate) {
        guard let token = KeychainHelper.loadToken() else { return }
        Task {
            await scenePortrait.pickCandidate(token: token, candidateId: candidate.id) {
                Task { await appState.loadCurrentPet() }
            }
        }
    }
}
