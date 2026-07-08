import SwiftUI

struct HugsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            if appState.hugs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.rose.opacity(0.4))
                    Text(s.hugsEmptyTitle)
                        .font(AppFonts.body(16))
                        .foregroundColor(AppColors.ink)
                    Text(s.hugsEmptyBody)
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
            } else {
                List {
                    Section {
                        Text(s.hugsCount(appState.hugs.count))
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                            .listRowBackground(AppColors.paper)
                    }
                    ForEach(appState.hugs) { hug in
                        HugRow(hug: hug)
                            .listRowBackground(AppColors.white)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppColors.paper)
            }
        }
        .navigationTitle(s.hugsNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            appState.newHugCount = 0
        }
    }
}

struct HugRow: View {
    let hug: Hug
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        let s = ls.strings
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.rose.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.rose)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(hug.visitorName ?? s.hugsAnonymous)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text(s.hugsAction)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted)
            }
            Spacer()
            Text(hug.createdAt, style: .relative)
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.muted)
        }
        .padding(.vertical, 4)
    }
}
