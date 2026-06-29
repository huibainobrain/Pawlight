import SwiftUI

struct LetterEditView: View {
    let existingLetter: Letter?
    @Binding var isPresented: Bool

    @EnvironmentObject var appState: AppState

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
            AppColors.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Title field
                    TextField("标题，可选", text: $title)
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 14)
                        .onChange(of: title) { _, new in
                            if new.count > maxTitle { title = String(new.prefix(maxTitle)) }
                        }

                    Divider()
                        .padding(.horizontal, 20)

                    // MARK: Writing prompts (new letter, empty content)
                    if isNewLetter && content.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("有些话不需要整理好，想TA的时候写下来就可以。")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted.opacity(0.75))
                                .lineSpacing(3)
                                .padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(["今天想对TA说的话", "突然想起的一件小事", "没有来得及说出口的话", "想慢慢留在这里的话"], id: \.self) { prompt in
                                        Text(prompt)
                                            .font(AppFonts.body(12))
                                            .foregroundColor(AppColors.muted)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(AppColors.white)
                                            .cornerRadius(14)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.line, lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 8)
                    }

                    // MARK: Content editor
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("想对TA说的话，慢慢写在这里……")
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
                            .focused($contentFocused)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // MARK: Char counter
                    HStack(spacing: 6) {
                        if isOverLimit {
                            Text("这封信有点长了，可以稍微精简一点。")
                                .font(AppFonts.body(12))
                                .foregroundColor(AppColors.rose)
                        }
                        Spacer()
                        Text("\(content.count) / \(maxContent)")
                            .font(AppFonts.body(12))
                            .foregroundColor(isOverLimit ? AppColors.rose : AppColors.muted)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // MARK: Save error
                    if saveError {
                        Text("这封信暂时没有保存成功，请稍后再试。")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.rose)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                    }

                    // MARK: Privacy notice
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.muted.opacity(0.45))
                            .padding(.top, 2)
                        Text("这封信只会留在天堂信箱里，不会出现在分享出去的纪念页中。")
                            .font(AppFonts.body(12))
                            .foregroundColor(AppColors.muted.opacity(0.45))
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // MARK: Delete button (edit mode only)
                    if existingLetter != nil {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text(isDeleting ? "删除中……" : "删除这封信")
                                .font(AppFonts.body(14))
                                .foregroundColor(AppColors.rose.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 48)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("写给TA")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(hasChanges)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if hasChanges { showCancelAlert = true } else { isPresented = false }
                }
                .foregroundColor(AppColors.muted)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { save() } label: {
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
        .onAppear {
            let t = existingLetter?.title ?? ""
            let c = existingLetter?.content ?? ""
            title = t
            content = c
            originalTitle = t
            originalContent = c
            if isNewLetter { contentFocused = true }
        }
        .alert("你还没有保存这封信", isPresented: $showCancelAlert) {
            Button("继续写", role: .cancel) {}
            Button("确认退出", role: .destructive) { isPresented = false }
        } message: {
            Text("你还没有保存这封信，确认要退出吗？")
        }
        .alert("要删除这封信吗？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { deleteLetter() }
        } message: {
            Text("删除后，这封信将不会再保留在天堂信箱中。")
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("这封信暂时没能删除，请稍后再试。")
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
                isPresented = false
            } catch {
                print("deleteLetter error: \(error)")
                isDeleting = false
                showDeleteError = true
            }
        }
    }
}
