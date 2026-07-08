import SwiftUI

struct LetterDetailView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    @State private var letter: Letter
    @State private var showEdit = false

    init(letter: Letter, isPresented: Binding<Bool>) {
        self._letter = State(initialValue: letter)
        self._isPresented = isPresented
    }

    private var s: Strings { ls.strings }

    private var displayTitle: String {
        if let t = letter.title, !t.trimmingCharacters(in: .whitespaces).isEmpty { return t }
        return s.letterDetailDefaultTitle
    }

    private var wasEdited: Bool {
        guard let updated = letter.updatedAt else { return false }
        return updated.timeIntervalSince(letter.createdAt) > 60
    }

    private var dateInfoText: String {
        let base = s.letterWrittenOn(letter.createdAt)
        if wasEdited, let updated = letter.updatedAt {
            return base + " · " + s.letterEditedOn(updated)
        }
        return base
    }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()

            GeometryReader { geo in
                Image("letter_detail_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    Text(displayTitle)
                        .font(AppFonts.serif(22, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(dateInfoText)
                        .font(AppFonts.body(13))
                        .foregroundStyle(AppColors.muted.opacity(0.52))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    Text(letter.content)
                        .font(AppFonts.body(17))
                        .foregroundStyle(AppColors.ink)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.muted.opacity(0.42))
                            .padding(.top, 2)
                        Text(s.letterDetailPrivacy)
                            .font(AppFonts.body(12))
                            .foregroundStyle(AppColors.muted.opacity(0.42))
                            .lineSpacing(3)
                    }
                    .padding(.top, 32)
                }
                .padding(.horizontal, 56)
                .padding(.top, 96)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(AppColors.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(s.letterDetailNavTitle)
                    .font(.headline)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(s.edit) { showEdit = true }
                    .foregroundStyle(AppColors.greenDeep)
                    .fontWeight(.medium)
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            LetterEditView(
                existingLetter: letter,
                isPresented: $showEdit,
                onSave: { updated in letter = updated },
                onDelete: { isPresented = false }
            )
        }
    }
}
