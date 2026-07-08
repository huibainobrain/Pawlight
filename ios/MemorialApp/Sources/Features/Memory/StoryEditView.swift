import SwiftUI

struct StoryEditView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isSaving = false
    @State private var showCancelAlert = false
    @State private var showClearAlert = false
    @State private var saveError = false
    @FocusState private var focused: Bool

    private var s: Strings { ls.strings }
    private let maxLength = 1000

    private var isFirstTime: Bool { originalContent.isEmpty }
    private var hasChanges: Bool { content != originalContent }
    private var isOverLimit: Bool { content.count > maxLength }
    private var canSave: Bool { hasChanges && !isSaving && !isOverLimit }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                navHeader
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        descriptionArea
                        promptTagsArea
                            .padding(.top, 14)
                        inputCard
                            .padding(.top, 16)
                        if saveError {
                            Text(s.storySaveError)
                                .font(AppFonts.body(13))
                                .foregroundStyle(AppColors.rose)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                        publicNotice
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            let existing = appState.story?.content ?? ""
            content = existing
            originalContent = existing
            focused = true
        }
        .alert(s.storyUnsavedTitle, isPresented: $showCancelAlert) {
            Button(s.continueEditing, role: .cancel) {}
            Button(s.storyConfirmExit, role: .destructive) { dismiss() }
        } message: {
            Text(s.storyUnsavedBody)
        }
        .alert(s.storyClearTitle, isPresented: $showClearAlert) {
            Button(s.continueEditing, role: .cancel) {}
            Button(s.storyClearBtn, role: .destructive) { performSave() }
        } message: {
            Text(s.storyClearBody)
        }
    }

    // MARK: - 顶部导航

    private var navHeader: some View {
        HStack {
            Button {
                if hasChanges { showCancelAlert = true } else { dismiss() }
            } label: {
                Text(s.cancel)
                    .font(AppFonts.body(15))
                    .foregroundStyle(AppColors.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.muted.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Spacer()

            Text(s.storyNavTitle)
                .font(AppFonts.body(16, weight: .medium))
                .foregroundStyle(AppColors.ink)

            Spacer()

            Button { handleSave() } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.75)
                            .frame(width: 20, height: 20)
                            .tint(AppColors.white)
                    } else {
                        Text(s.save)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundStyle(canSave ? AppColors.white : AppColors.muted.opacity(0.36))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(canSave ? AppColors.greenDeep : AppColors.muted.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 说明文字

    private var descriptionArea: some View {
        Group {
            if isFirstTime {
                Text(s.storyFirstTimeBody)
                    .font(AppFonts.body(15))
                    .foregroundStyle(AppColors.muted)
                    .lineSpacing(5)
            } else {
                Text(s.storyReturningBody)
                    .font(AppFonts.body(14))
                    .foregroundStyle(AppColors.muted.opacity(0.68))
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - 写作提示标签

    private var promptTagsArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StoryPromptTag(icon: "heart",    iconColor: AppColors.rose.opacity(0.68),   text: s.storyPrompt1)
                StoryPromptTag(icon: "leaf",     iconColor: AppColors.green.opacity(0.65),  text: s.storyPrompt2)
                StoryPromptTag(icon: "star",     iconColor: AppColors.gold.opacity(0.70),   text: s.storyPrompt3)
            }
            StoryPromptTag(
                icon: "sun.min",
                iconColor: Color(red: 0.85, green: 0.63, blue: 0.28).opacity(0.75),
                text: s.storyPrompt4
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 输入卡片

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 空态 placeholder（居中显示）
                if content.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "quill.pen")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.muted.opacity(0.20))
                        Text(s.storyPlaceholder)
                            .font(AppFonts.body(14))
                            .foregroundStyle(AppColors.muted.opacity(0.34))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 46)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $content)
                    .font(AppFonts.body(16))
                    .foregroundStyle(AppColors.ink)
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 260)
                    .focused($focused)
                    .padding(.top, 2)
                    .padding(.horizontal, 2)
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)

            // 字数统计（卡片内右下角）
            HStack(spacing: 6) {
                if isOverLimit {
                    Text(s.storyOverLimit)
                        .font(AppFonts.body(11))
                        .foregroundStyle(AppColors.rose)
                }
                Spacer()
                Text("\(content.count) / \(maxLength)")
                    .font(AppFonts.body(12))
                    .foregroundStyle(isOverLimit ? AppColors.rose : AppColors.muted.opacity(0.40))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.line, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - 公开边界提示

    private var publicNotice: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.muted.opacity(0.44))
                .padding(.top, 1)
            Text(s.storyPublicNotice)
                .font(AppFonts.body(12))
                .foregroundStyle(AppColors.muted.opacity(0.50))
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 保存逻辑（不变）

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

// MARK: - 写作提示胶囊标签

private struct StoryPromptTag: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
            Text(text)
                .font(AppFonts.body(13))
                .foregroundStyle(AppColors.muted.opacity(0.72))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.line, lineWidth: 1))
    }
}
