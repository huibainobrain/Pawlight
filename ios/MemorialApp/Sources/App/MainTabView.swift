import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)
            MemoryView()
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("回忆", systemImage: "heart.fill") }
                .tag(1)
            MineView()
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(2)
        }
        .overlay(alignment: .bottom) {
            PillTabBar()
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .environmentObject(appState)
                .offset(y: appState.tabBarHidden ? 120 : 0)
                .animation(.easeInOut(duration: 0.22), value: appState.tabBarHidden)
        }
        .onAppear { applyTransparentTabBar() }
        #if DEBUG
        .overlay(alignment: .topLeading) {
            // Hidden whenever a full-screen subpage (Mailbox, Album, Hugs, ...) is
            // pushed — tabBarHidden is already true in exactly those cases, and this
            // button's fixed position otherwise overlaps their back button.
            if !appState.tabBarHidden {
                Button { appState.resetAll() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.muted)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 56)
            }
        }
        #endif
    }

    private func applyTransparentTabBar() {
        UITabBar.appearance().isHidden = true
    }
}

// MARK: - 胶囊 TabBar

private struct PillTabBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        let items: [(icon: String, filled: String, label: String)] = [
            ("house",  "house.fill",  ls.strings.tabHome),
            ("heart",  "heart.fill",  ls.strings.tabMemory),
            ("person", "person.fill", ls.strings.tabMe),
        ]
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                PillTabItem(
                    icon: item.icon,
                    filledIcon: item.filled,
                    label: item.label,
                    isSelected: appState.selectedTab == idx
                ) { appState.selectedTab = idx }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.black.opacity(0.07), radius: 18, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}

private struct PillTabItem: View {
    let icon: String
    let filledIcon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 13)
                            .fill(AppColors.green.opacity(0.18))
                            .frame(width: 46, height: 26)
                    }
                    Image(systemName: isSelected ? filledIcon : icon)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? AppColors.greenDeep : AppColors.muted.opacity(0.60))
                }
                Text(label)
                    .font(AppFonts.body(10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? AppColors.greenDeep : AppColors.muted.opacity(0.60))
            }
            .padding(.vertical, 6)
        }
    }
}
