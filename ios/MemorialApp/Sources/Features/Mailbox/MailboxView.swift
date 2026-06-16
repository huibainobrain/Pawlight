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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(letter.title ?? "无标题")
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.ink)
                        Text(letter.content)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                            .lineLimit(2)
                        Text(letter.createdAt, style: .date)
                            .font(AppFonts.body(11))
                            .foregroundColor(AppColors.muted.opacity(0.7))
                    }
                    .padding(.vertical, 4)
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

struct LetterEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var isSaving = false
    @FocusState private var contentFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    TextField("标题（选填）", text: $title)
                        .font(AppFonts.body(17, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    Divider().padding(.horizontal, 20)
                    TextEditor(text: $content)
                        .font(AppFonts.body(16))
                        .foregroundColor(AppColors.ink)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .focused($contentFocused)
                }
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
        isSaving = true
        // TODO: POST /api/v1/pets/{pet_id}/letters
        let letter = Letter(
            id: UUID().uuidString,
            petId: appState.currentPet?.id ?? "",
            userId: appState.currentUser?.id ?? "",
            title: title.isEmpty ? nil : title,
            content: content,
            createdAt: Date(),
            updatedAt: nil
        )
        appState.letters.insert(letter, at: 0)
        isSaving = false
        dismiss()
    }
}
