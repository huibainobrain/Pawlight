import SwiftUI

struct LetterEditView: View {
    let existingLetter: Letter?
    @Binding var isPresented: Bool
    var onSave: ((Letter) -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    @State private var title = ""
    @State private var content = ""
    @State private var originalTitle = ""
    @State private var originalContent = ""
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var saveError = false
    @State private var showCancelAlert = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @FocusState private var contentFocused: Bool

    private let maxContent = 2000
    private let maxTitle = 30

    private var isNewLetter: Bool { existingLetter == nil }
    private var hasChanges: Bool { title != originalTitle || content != originalContent }
    private var trimmedContent: String { content.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isOverLimit: Bool { content.count > maxContent }
    private var canSave: Bool { hasChanges && !trimmedContent.isEmpty && !isOverLimit && !isSaving }

    var body: some View {
        ZStack {
            // Paper color fills any area the image doesn't cover (bottom gap with .fit).
            AppColors.paper.ignoresSafeArea()
            // .fit fills the full width without horizontal cropping, keeping the image
            // symmetric. alignment: .top anchors the botanical header to the nav bar.
            Image("mailbox_paper_bg")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 1. Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(s.letterEditTitleLabel)
                            .font(AppFonts.body(11))
                            .foregroundColor(AppColors.muted.opacity(0.5))
                        TextField(s.letterEditTitlePlaceholder, text: $title)
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(AppColors.ink)
                            .onChange(of: title) { _, new in
                                if new.count > maxTitle { title = String(new.prefix(maxTitle)) }
                            }
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    Divider().padding(.horizontal, 36)

                    // MARK: 2. Writing prompts (new letter, before typing)
                    if isNewLetter && content.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(s.letterEditPromptsLabel)
                                .font(AppFonts.body(12))
                                .foregroundColor(AppColors.muted.opacity(0.55))
                                .padding(.horizontal, 36)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach([s.letterEditPrompt1, s.letterEditPrompt2, s.letterEditPrompt3], id: \.self) { prompt in
                                        Button {
                                            content = prompt + "："
                                            contentFocused = true
                                        } label: {
                                            Text(prompt)
                                                .font(AppFonts.body(12))
                                                .foregroundColor(AppColors.muted)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.white)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(AppColors.line, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 36)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }

                    // MARK: 3. Content editor (main writing area)
                    ZStack(alignment: .bottomTrailing) {
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text(s.letterEditContentPlaceholder)
                                    .font(AppFonts.body(16))
                                    .foregroundColor(AppColors.muted.opacity(0.45))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(AppFonts.body(16))
                                .foregroundColor(AppColors.ink)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 300)
                                .focused($contentFocused)
                                .padding(.bottom, 28)
                        }
                        .padding(.horizontal, 36)
                        .padding(.top, 32)

                        // Char counter anchored inside the writing area, bottom-right
                        HStack(spacing: 8) {
                            if isOverLimit {
                                Text(s.letterEditOverLimit)
                                    .font(AppFonts.body(11))
                                    .foregroundColor(AppColors.rose)
                            }
                            Text("\(content.count) / \(maxContent)")
                                .font(AppFonts.body(11))
                                .foregroundColor(isOverLimit ? AppColors.rose : AppColors.muted.opacity(0.4))
                        }
                        .padding(.trailing, 32)
                        .padding(.bottom, 10)
                    }

                    // MARK: Save error
                    if saveError {
                        Text(s.letterEditSaveError)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.rose)
                            .padding(.horizontal, 36)
                            .padding(.top, 8)
                    }

                    // MARK: 4. Privacy notice
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.muted.opacity(0.38))
                            .padding(.top, 2)
                        Text(s.letterEditPrivacyNotice)
                            .font(AppFonts.body(12))
                            .foregroundColor(AppColors.muted.opacity(0.38))
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 24)

                    // MARK: 5. Delete (edit mode only)
                    if existingLetter != nil {
                        Divider()
                            .padding(.horizontal, 36)
                            .padding(.top, 32)
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text(isDeleting ? s.letterEditDeletingBtn : s.letterEditDeleteBtn)
                                .font(AppFonts.body(14))
                                .foregroundColor(AppColors.rose.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal, 36)
                    }

                    Spacer(minLength: 60)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(s.letterEditNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(s.cancel) {
                    if hasChanges { showCancelAlert = true } else { isPresented = false }
                }
                .foregroundColor(AppColors.muted)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { save() } label: {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text(s.save)
                            .foregroundColor(canSave ? AppColors.greenDeep : AppColors.muted)
                            .fontWeight(.medium)
                    }
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            let t = existingLetter?.title ?? ""
            let c = existingLetter?.content ?? ""
            title = t
            content = c
            originalTitle = t
            originalContent = c
            if isNewLetter { contentFocused = true }
        }
        .alert(s.letterEditUnsavedTitle(isNewLetter), isPresented: $showCancelAlert) {
            Button(s.continueEditing, role: .cancel) {}
            Button(s.leaveWithoutSaving, role: .destructive) { isPresented = false }
        } message: {
            Text(s.letterEditUnsavedBody(isNewLetter))
        }
        .alert(s.letterEditDeleteAlertTitle, isPresented: $showDeleteConfirm) {
            Button(s.cancel, role: .cancel) {}
            Button(s.delete, role: .destructive) { deleteLetter() }
        } message: {
            Text(s.letterEditDeleteAlertBody)
        }
        .alert(s.letterEditDeleteErrorTitle, isPresented: $showDeleteError) {
            Button(s.ok, role: .cancel) {}
        } message: {
            Text(s.letterEditDeleteErrorBody)
        }
    }

    // MARK: Save

    private func save() {
        let body = trimmedContent
        guard !body.isEmpty else { return }
        let t = title.trimmingCharacters(in: .whitespaces)
        isSaving = true
        saveError = false
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else {
                let hasToken = KeychainHelper.loadToken() != nil
                print("[LetterEdit] save guard failed — token:\(hasToken) petId:\(appState.currentPet?.id ?? "nil")")
                saveError = true
                isSaving = false
                return
            }
            do {
                if let existing = existingLetter {
                    let api = try await APIClient.shared.updateLetter(
                        token: token, petId: petId, letterId: existing.id,
                        title: t.isEmpty ? nil : t, content: body
                    )
                    let updated = Letter(id: api.id, petId: api.petId,
                                        userId: appState.currentUser?.id ?? "",
                                        title: api.title, content: api.content,
                                        createdAt: api.createdAt, updatedAt: api.updatedAt)
                    if let idx = appState.letters.firstIndex(where: { $0.id == existing.id }) {
                        appState.letters[idx] = updated
                    }
                    onSave?(updated)
                } else {
                    let api = try await APIClient.shared.createLetter(
                        token: token, petId: petId,
                        title: t.isEmpty ? nil : t, content: body
                    )
                    let letter = Letter(id: api.id, petId: api.petId,
                                        userId: appState.currentUser?.id ?? "",
                                        title: api.title, content: api.content,
                                        createdAt: api.createdAt, updatedAt: api.updatedAt)
                    appState.letters.insert(letter, at: 0)
                }
                isSaving = false
                isPresented = false
            } catch {
                print("saveLetter error: \(error)")
                saveError = true
                isSaving = false
            }
        }
    }

    // MARK: Delete

    private func deleteLetter() {
        guard let letterId = existingLetter?.id else { return }
        isDeleting = true
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else {
                isDeleting = false
                showDeleteError = true
                return
            }
            do {
                try await APIClient.shared.deleteLetter(token: token, petId: petId, letterId: letterId)
                appState.letters.removeAll { $0.id == letterId }
                isDeleting = false
                if let onDelete = onDelete {
                    onDelete()
                } else {
                    isPresented = false
                }
            } catch {
                print("deleteLetter error: \(error)")
                isDeleting = false
                showDeleteError = true
            }
        }
    }
}
