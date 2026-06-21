import SwiftUI

struct StoryEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var isSaving = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    TextEditor(text: $content)
                        .font(AppFonts.body(16))
                        .foregroundColor(AppColors.ink)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .focused($focused)

                    if content.isEmpty {
                        Text("从第一次见到TA开始，或者最想念的一件小事……")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.muted.opacity(0.6))
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("TA的故事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("保存")
                                .foregroundColor(AppColors.greenDeep)
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            content = appState.story?.content ?? ""
            focused = true
        }
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                try await APIClient.shared.updatePet(token: token, petId: petId, body: ["story": trimmed])
                appState.story = Story(id: "story_\(petId)", petId: petId, content: trimmed,
                                       visibility: .publicLink, createdAt: Date(), updatedAt: Date())
                isSaving = false
                dismiss()
            } catch {
                print("saveStory error: \(error)")
                isSaving = false
            }
        }
    }
}
