import SwiftUI

struct StoryEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isSaving = false
    @State private var showCancelAlert = false
    @State private var showClearAlert = false
    @State private var saveError = false
    @FocusState private var focused: Bool

    private let maxLength = 1000

    private var isFirstTime: Bool { originalContent.isEmpty }
    private var hasChanges: Bool { content != originalContent }
    private var isOverLimit: Bool { content.count > maxLength }
    private var canSave: Bool { hasChanges && !isSaving && !isOverLimit }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: 顶部引导（首次 or 编辑提示）
                        if isFirstTime {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("写下你记得的TA。\n可以是一件小事，一个习惯，或者第一次见到TA的那天。")
                                    .font(AppFonts.body(15))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(5)
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(["第一次见到TA", "TA的小习惯", "最想念的一件事", "TA陪你的日子"], id: \.self) { prompt in
                                            Text(prompt)
                                                .font(AppFonts.body(13))
                                                .foregroundColor(AppColors.muted)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(AppColors.white)
                                                .cornerRadius(20)
                                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.line, lineWidth: 1))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        } else {
                            Text("你可以继续补充这段故事，或者改成现在更想留下的样子。")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted.opacity(0.75))
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 12)
                        }

                        // MARK: 编辑区
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("比如：第一次见到TA的时候，它还很小。后来它最喜欢趴在窗边晒太阳……")
                                    .font(AppFonts.body(16))
                                    .foregroundColor(AppColors.muted.opacity(0.4))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(AppFonts.body(16))
                                .foregroundColor(AppColors.ink)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 240)
                                .focused($focused)
                        }
                        .padding(.horizontal, 16)

                        // MARK: 字数提示
                        HStack(spacing: 6) {
                            if isOverLimit {
                                Text("故事有点长了，可以稍微精简一点。")
                                    .font(AppFonts.body(12))
                                    .foregroundColor(AppColors.rose)
                            }
                            Spacer()
                            Text("\(content.count) / \(maxLength)")
                                .font(AppFonts.body(12))
                                .foregroundColor(isOverLimit ? AppColors.rose : AppColors.muted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // MARK: 保存失败提示
                        if saveError {
                            Text("故事暂时没有保存成功，请稍后再试。")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.rose)
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                        }

                        // MARK: 公开边界说明
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.muted.opacity(0.5))
                                .padding(.top, 1)
                            Text("这段故事会留在TA的纪念主页里。分享纪念页时，也记得TA的人可以看到。")
                                .font(AppFonts.body(12))
                                .foregroundColor(AppColors.muted.opacity(0.5))
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("TA的故事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(AppColors.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { handleSave() } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("保存")
                                .foregroundColor(canSave ? AppColors.greenDeep : AppColors.muted)
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            let existing = appState.story?.content ?? ""
            content = existing
            originalContent = existing
            focused = true
        }
        .alert("你还没有保存故事", isPresented: $showCancelAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("确认退出", role: .destructive) { dismiss() }
        } message: {
            Text("你还没有保存你的故事，确认要退出吗？")
        }
        .alert("要清空TA的故事吗？", isPresented: $showClearAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("清空故事", role: .destructive) { performSave() }
        } message: {
            Text("清空后，回忆页和分享出去的纪念页将不再展示这段故事。")
        }
    }

    private func handleSave() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !originalContent.isEmpty && trimmed.isEmpty {
            showClearAlert = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        saveError = false
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                try await APIClient.shared.updatePet(token: token, petId: petId, body: ["story": trimmed])
                if trimmed.isEmpty {
                    appState.story = nil
                } else {
                    appState.story = Story(id: "story_\(petId)", petId: petId, content: trimmed,
                                           visibility: .publicLink, createdAt: Date(), updatedAt: Date())
                }
                isSaving = false
                dismiss()
            } catch {
                print("saveStory error: \(error)")
                saveError = true
                isSaving = false
            }
        }
    }
}
