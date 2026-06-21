import SwiftUI

struct MemorialSentenceEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("一句纪念语")
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .padding(.top, 24)
                    TextField("愿你在有风和阳光的地方……", text: $text, axis: .vertical)
                        .font(AppFonts.serif(17))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 32)
                        .focused($focused)
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.foregroundColor(AppColors.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        appState.currentPet?.memorialSentence = finalText
                        Task {
                            guard let token = KeychainHelper.loadToken(),
                                  let petId = appState.currentPet?.id else { return }
                            try? await APIClient.shared.updatePet(token: token, petId: petId,
                                                                   body: ["memorialSentence": finalText])
                        }
                        dismiss()
                    }
                    .foregroundColor(AppColors.greenDeep)
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            text = appState.currentPet?.memorialSentence ?? ""
            focused = true
        }
    }
}
