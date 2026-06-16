import SwiftUI

struct HugsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            if appState.hugs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.rose.opacity(0.4))
                    Text("还没有抱抱记录")
                        .font(AppFonts.body(16))
                        .foregroundColor(AppColors.ink)
                    Text("把纪念页分享给也记得TA的人，\n他们可以轻轻抱抱TA。")
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
            } else {
                List {
                    Section {
                        Text("共 \(appState.hugs.count) 个抱抱")
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
        .navigationTitle("抱抱记录")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appState.newHugCount = 0
        }
    }
}

struct HugRow: View {
    let hug: Hug

    var body: some View {
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
                Text(hug.visitorName ?? "匿名访客")
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.ink)
                Text("轻轻抱了抱TA")
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
