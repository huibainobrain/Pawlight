import SwiftUI

struct MemorialSentenceEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var originalText = ""
    @State private var isSaving = false
    @State private var saveError = false
    @State private var showCancelAlert = false
    @FocusState private var focused: Bool

    private var hasChanges: Bool { text != originalText }

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
                    if saveError {
                        Text("纪念语暂时没有保存成功，请稍后再试。")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.rose)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges { showCancelAlert = true } else { dismiss() }
                    }.foregroundColor(AppColors.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("保存")
                                .foregroundColor(hasChanges ? AppColors.greenDeep : AppColors.muted)
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
        }
        .onAppear {
            let t = appState.currentPet?.memorialSentence ?? ""
            text = t
            originalText = t
            focused = true
        }
        .alert("你还没有保存纪念语", isPresented: $showCancelAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("确认退出", role: .destructive) { dismiss() }
        } message: {
            Text("你还没有保存这句纪念语，确认要退出吗？")
        }
    }

    private func save() {
        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        saveError = false
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                try await APIClient.shared.updatePet(token: token, petId: petId,
                                                     body: ["memorialSentence": finalText])
                appState.currentPet?.memorialSentence = finalText
                isSaving = false
                dismiss()
            } catch {
                print("saveMemorialSentence error: \(error)")
                isSaving = false
                saveError = true
            }
        }
    }
}
