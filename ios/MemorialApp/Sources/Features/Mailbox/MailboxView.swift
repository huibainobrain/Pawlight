import SwiftUI

struct MailboxView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLetterEdit = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            if appState.letters.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "envelope")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.gold.opacity(0.5))
                    Text("想说的话，慢慢写在这里。")
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.muted)
                }
            } else {
                List(appState.letters) { letter in
                    LetterRow(letter: letter)
                        .listRowBackground(AppColors.paper)
                }
                .listStyle(.plain)
                .background(AppColors.paper)
            }
        }
        .navigationTitle("天堂信箱")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showLetterEdit = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(AppColors.greenDeep)
                }
            }
        }
        .sheet(isPresented: $showLetterEdit) { LetterEditView() }
    }
}

struct LetterRow: View {
    let letter: Letter

    var body: some View {
        let lines = letter.content.components(separatedBy: "\n").filter { !$0.isEmpty }
        VStack(alignment: .leading, spacing: 6) {
            Text(lines.first ?? "")
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(AppColors.ink)
            if lines.count > 1 {
                Text(lines.dropFirst().joined(separator: "\n"))
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted)
                    .lineLimit(2)
            }
            Text(letter.createdAt, style: .date)
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.muted.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

struct LetterEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var isSaving = false
    @FocusState private var contentFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                TextEditor(text: $content)
                    .font(AppFonts.body(16))
                    .foregroundColor(AppColors.ink)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .focused($contentFocused)
            }
            .navigationTitle("写给TA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.foregroundColor(AppColors.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .foregroundColor(AppColors.greenDeep)
                        .fontWeight(.medium)
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .onAppear { contentFocused = true }
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                let apiLetter = try await APIClient.shared.createLetter(token: token, petId: petId, content: trimmed)
                let letter = Letter(id: apiLetter.id, petId: apiLetter.petId,
                                    userId: appState.currentUser?.id ?? "",
                                    title: nil, content: apiLetter.content,
                                    createdAt: apiLetter.createdAt, updatedAt: apiLetter.updatedAt)
                appState.letters.insert(letter, at: 0)
                isSaving = false
                dismiss()
            } catch {
                print("createLetter error: \(error)")
                isSaving = false
            }
        }
    }
}
