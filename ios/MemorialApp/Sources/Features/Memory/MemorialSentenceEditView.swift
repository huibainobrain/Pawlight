import SwiftUI

struct MemorialSentenceEditView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var originalText = ""
    @State private var isSaving = false
    @State private var saveError = false
    @State private var showCancelAlert = false
    @FocusState private var focused: Bool

    private var s: Strings { ls.strings }
    private let maxLength = 30
    private var hasChanges: Bool { text != originalText }

    // 背景图中输入区域比例坐标（相对于全屏高度）
    private let inputTopRatio: CGFloat = 0.44
    private let inputHeightRatio: CGFloat = 0.28
    private let inputHPad: CGFloat = 40

    var body: some View {
        // ─────────────────────────────────────────────────────────────────
        // 关键：GeometryReader 本身 **不加** ignoresSafeArea()
        //   → geo.safeAreaInsets.top = 真实设备值（iPhone 17 Pro ≈ 59pt）
        //   → geo.size.height = 内容区高度（安全区内）
        // 背景图通过自己的 ignoresSafeArea() + offset 铺满全屏
        // ─────────────────────────────────────────────────────────────────
        GeometryReader { geo in
            let safeTop    = geo.safeAreaInsets.top      // ≈ 59pt (Dynamic Island)
            let safeBottom = geo.safeAreaInsets.bottom   // ≈ 34pt
            let totalW     = geo.size.width              // ≈ 393pt
            let contentH   = geo.size.height             // ≈ 759pt（不含安全区）
            let totalH     = contentH + safeTop + safeBottom // ≈ 852pt（全屏）

            ZStack(alignment: .topLeading) {

                // ── 背景图：全屏铺满，延伸至状态栏后方 ───────────────
                // frame = 全屏尺寸，offset 上移 safeTop 覆盖状态栏，
                // ignoresSafeArea() 允许渲染超出安全区边界
                Image("memorial_sentence_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: totalW, height: totalH)
                    .offset(y: -safeTop)
                    .ignoresSafeArea()

                // ── 顶部按钮：geo.y = 0 已是安全区顶（灵动岛以下）───
                // 只需加 12pt 视觉间距，不再需要额外补偿 safeAreaInsets
                HStack {
                    cancelButton
                    Spacer()
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── 透明输入层：按背景图比例定位 ────────────────────
                transparentInputLayer(
                    totalW: totalW,
                    totalH: totalH,
                    safeTop: safeTop
                )
            }
        }
        .onAppear {
            let t = appState.currentPet?.memorialSentence ?? ""
            text = t
            originalText = t
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focused = true
            }
        }
        .alert(s.memorialUnsavedTitle, isPresented: $showCancelAlert) {
            Button(s.continueEditing, role: .cancel) {}
            Button(s.storyConfirmExit, role: .destructive) { dismiss() }
        } message: {
            Text(s.memorialUnsavedBody)
        }
        .alert(s.saveFailed, isPresented: $saveError) {
            Button(s.ok, role: .cancel) { saveError = false }
        } message: {
            Text(s.memorialSaveErrorBody)
        }
    }

    // MARK: - 透明输入覆盖层

    @ViewBuilder
    private func transparentInputLayer(
        totalW: CGFloat,
        totalH: CGFloat,
        safeTop: CGFloat
    ) -> some View {
        // 目标屏幕 y = totalH * inputTopRatio
        // geo 坐标 y = 屏幕 y - safeTop（geo 原点在安全区顶，不是屏幕顶）
        let targetY = totalH * inputTopRatio - safeTop

        ZStack(alignment: .topLeading) {

            // Placeholder
            if text.isEmpty {
                Text(s.memorialPlaceholder)
                    .font(AppFonts.serif(16))
                    .foregroundStyle(AppColors.muted.opacity(0.38))
                    .padding(.leading, 10)
                    .padding(.top, 12)
                    .allowsHitTesting(false)
            }

            // 真实输入框（透明，无边框）
            TextEditor(text: $text)
                .font(AppFonts.serif(16))
                .foregroundStyle(AppColors.ink.opacity(0.76))
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(.horizontal, 6)
                .padding(.top, 4)
                .focused($focused)
                .onChange(of: text) { _, new in
                    if new.count > maxLength {
                        text = String(new.prefix(maxLength))
                    }
                }

            // 字数统计：右下角，覆盖背景图静态 0/30
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(text.count) / \(maxLength)")
                        .font(AppFonts.body(11))
                        .foregroundStyle(AppColors.muted.opacity(0.55))
                        .padding(.trailing, 14)
                        .padding(.bottom, 14)
                }
            }
        }
        .frame(
            width: totalW - inputHPad * 2,
            height: totalH * inputHeightRatio
        )
        .background(.clear)
        .offset(x: inputHPad, y: targetY)
    }

    // MARK: - 取消按钮

    private var cancelButton: some View {
        Button {
            if hasChanges { showCancelAlert = true } else { dismiss() }
        } label: {
            Text(s.cancel)
                .font(AppFonts.body(15))
                .foregroundStyle(AppColors.ink.opacity(0.52))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.78))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - 保存按钮

    private var saveButton: some View {
        Button { save() } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.85)
                        .frame(width: 20, height: 20)
                } else {
                    Text(s.save)
                        .font(AppFonts.body(15, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                hasChanges
                    ? AppColors.greenDeep.opacity(0.84)
                    : AppColors.muted.opacity(0.20)
            )
            .clipShape(Capsule())
            .shadow(
                color: AppColors.greenDeep.opacity(hasChanges ? 0.20 : 0),
                radius: 6, x: 0, y: 2
            )
        }
        .disabled(!hasChanges || isSaving)
        .animation(.easeInOut(duration: 0.18), value: hasChanges)
    }

    // MARK: - 保存逻辑（不变）

    private func save() {
        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        saveError = false
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                try await APIClient.shared.updatePet(token: token, petId: petId,
                                                     body: ["memorialSentence": finalText])
                appState.currentPet?.memorialSentence = finalText
                isSaving = false
                dismiss()
            } catch {
                print("saveMemorialSentence error: \(error)")
                isSaving = false
                saveError = true
            }
        }
    }
}
