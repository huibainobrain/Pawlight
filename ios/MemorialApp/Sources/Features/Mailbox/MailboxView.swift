import SwiftUI

struct MailboxView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingLetter: Letter? = nil
    @State private var showLetterEdit = false
    @State private var isLoading = false
    @State private var loadError = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            Group {
                if isLoading {
                    ProgressView()
                } else if loadError && appState.letters.isEmpty {
                    errorStateView
                } else if appState.letters.isEmpty {
                    emptyStateView
                } else {
                    letterListView
                }
            }
        }
        .navigationTitle("天堂信箱")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingLetter = nil
                    showLetterEdit = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(AppColors.greenDeep)
                }
            }
        }
        .navigationDestination(isPresented: $showLetterEdit) {
            LetterEditView(existingLetter: editingLetter, isPresented: $showLetterEdit)
        }
        .task { await loadLetters() }
    }

    // MARK: Empty State

    @ViewBuilder private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.gold.opacity(0.1))
                        .frame(width: 96, height: 96)
                    Image(systemName: "envelope")
                        .font(.system(size: 34))
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                VStack(spacing: 12) {
                    Text("还没有写给TA的信")
                        .font(AppFonts.serif(19, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text("想说的话，可以慢慢写在这里。\n这些信只给主人自己看，不会出现在分享出去的纪念页里。")
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }
                Button {
                    editingLetter = nil
                    showLetterEdit = true
                } label: {
                    Text("写第一封信")
                        .font(AppFonts.body(15, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(AppColors.greenDeep)
                        .cornerRadius(10)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Letter List

    @ViewBuilder private var letterListView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.muted.opacity(0.45))
                Text("这些信只给主人自己看。")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppColors.paper)

            List {
                ForEach(appState.letters) { letter in
                    Button {
                        editingLetter = letter
                        showLetterEdit = true
                    } label: {
                        LetterRow(letter: letter)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppColors.paper)
                    .listRowSeparatorTint(AppColors.line)
                }
            }
            .listStyle(.plain)
            .background(AppColors.paper)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Error State

    @ViewBuilder private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 34))
                .foregroundColor(AppColors.muted.opacity(0.35))
            VStack(spacing: 6) {
                Text("信件暂时加载不出来")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.muted)
                Text("可以稍后再试。")
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.muted.opacity(0.7))
            }
            Button("重新加载") {
                loadError = false
                Task { await loadLetters() }
            }
            .font(AppFonts.body(14))
            .foregroundColor(AppColors.greenDeep)
            .padding(.top, 4)
        }
    }

    // MARK: Data

    private func loadLetters() async {
        guard let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        if appState.letters.isEmpty { isLoading = true }
        do {
            let apiLetters = try await APIClient.shared.fetchLetters(token: token, petId: petId)
            appState.letters = apiLetters.map { l in
                Letter(id: l.id, petId: l.petId, userId: appState.currentUser?.id ?? "",
                       title: l.title, content: l.content,
                       createdAt: l.createdAt, updatedAt: l.updatedAt)
            }
            loadError = false
        } catch {
            if appState.letters.isEmpty { loadError = true }
        }
        isLoading = false
    }
}

// MARK: - Letter Row

struct LetterRow: View {
    let letter: Letter

    private var displayTitle: String {
        if let t = letter.title, !t.trimmingCharacters(in: .whitespaces).isEmpty { return t }
        return "写给TA的一封信"
    }
    private var displayDate: Date { letter.updatedAt ?? letter.createdAt }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayTitle)
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(AppColors.ink)
                .lineLimit(1)
            Text(letter.content)
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.muted)
                .lineLimit(2)
            Text(displayDate, style: .date)
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.muted.opacity(0.6))
        }
        .padding(.vertical, 6)
    }
}
