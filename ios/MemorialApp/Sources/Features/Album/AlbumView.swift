import SwiftUI
import PhotosUI

private enum UploadBannerState: Equatable {
    case idle
    case uploading(Int, Int)    // current index, total
    case allSuccess(Int)        // count
    case partial(Int, Int)      // succeeded, failed
    case allFailed
    case formatError
}

struct AlbumView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss

    private var s: Strings { ls.strings }

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var uploadState: UploadBannerState = .idle
    @State private var showLimitSheet = false
    @State private var wantsEntitlement = false
    @State private var showEntitlement = false
    @State private var selectedPhoto: Photo? = nil
    @State private var showOverLimitAlert = false
    @State private var overLimitSelected = 0
    @State private var overLimitAvailable = 0
    @State private var pendingPartialItems: [PhotosPickerItem] = []

    private var albumPhotos: [Photo] {
        appState.photos.filter { $0.type == .album }
            .sorted { $0.createdAt < $1.createdAt }
    }
    private var count: Int { albumPhotos.count }
    private var limit: Int { appState.photoLimit }
    private var atLimit: Bool { count >= limit }
    private var remainingSlots: Int { max(0, limit - count) }
    private var isUploading: Bool {
        if case .uploading = uploadState { return true }
        return false
    }
    private var showNotification: Bool {
        switch uploadState {
        case .allSuccess, .partial, .allFailed, .formatError: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 轻量通知（上传完成 / 失败）
                    if showNotification {
                        notificationBanner
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 计数行
                    capacityRow

                    // 内容区
                    if albumPhotos.isEmpty && !isUploading {
                        emptyStateView
                    } else {
                        photoGrid
                    }

                    // 公开边界提示
                    publicNotice
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: uploadState)
        .navigationTitle(s.albumNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .padding(8)
                        .background(AppColors.white.opacity(0.88))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                toolbarAddButton
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty else { return }
            selectedItems = []
            let available = remainingSlots
            if items.count > available {
                overLimitSelected = items.count
                overLimitAvailable = available
                pendingPartialItems = Array(items.prefix(available))
                showOverLimitAlert = true
            } else {
                handleMultiUpload(items: items)
            }
        }
        .alert(s.albumOverLimitTitle(overLimitSelected, overLimitAvailable), isPresented: $showOverLimitAlert) {
            Button(s.cancel, role: .cancel) { pendingPartialItems = [] }
            if overLimitAvailable > 0 {
                Button(s.albumUploadPartialBtn(overLimitAvailable)) {
                    let items = pendingPartialItems
                    pendingPartialItems = []
                    handleMultiUpload(items: items)
                }
            }
        } message: {
            Text(s.albumOverLimitBody(overLimitSelected, overLimitAvailable))
        }
        .sheet(isPresented: $showLimitSheet, onDismiss: {
            if wantsEntitlement { wantsEntitlement = false; showEntitlement = true }
        }) {
            LimitSheet(isPaid: appState.isPaid, limit: limit, onUpgrade: {
                wantsEntitlement = true; showLimitSheet = false
            })
        }
        .navigationDestination(isPresented: $showEntitlement) { EntitlementView() }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo).environmentObject(appState)
        }
    }

    // MARK: - 顶部"添加照片"按钮

    @ViewBuilder private var toolbarAddButton: some View {
        if isUploading {
            ProgressView().scaleEffect(0.78)
        } else if atLimit {
            Button { showLimitSheet = true } label: {
                Text(s.albumAddPhotoBtn)
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundStyle(AppColors.muted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.muted.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        } else {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: remainingSlots,
                matching: .images
            ) {
                Text(s.albumAddPhotoBtn)
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundStyle(AppColors.greenDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - 轻量通知（完成 / 失败）

    @ViewBuilder private var notificationBanner: some View {
        let (icon, iconColor, message) = notificationContent
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
            Text(message)
                .font(AppFonts.body(13))
                .foregroundStyle(AppColors.ink)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
    }

    private var notificationContent: (String, Color, String) {
        switch uploadState {
        case .allSuccess(let n):
            return ("checkmark.circle.fill", AppColors.greenDeep, s.albumSuccessMsg(n))
        case .partial(let ok, let fail):
            return ("exclamationmark.circle.fill", AppColors.gold, s.albumPartialMsg(ok, fail))
        case .allFailed:
            return ("xmark.circle.fill", AppColors.rose, s.albumAllFailedMsg)
        case .formatError:
            return ("xmark.circle.fill", AppColors.rose, s.albumFormatErrorMsg)
        default:
            return ("", .clear, "")
        }
    }

    // MARK: - 计数行

    private var capacityRow: some View {
        HStack(spacing: 0) {
            Text(s.albumCapacity(count, limit))
                .font(AppFonts.body(13))
                .foregroundStyle(atLimit ? AppColors.gold : AppColors.muted)
            if atLimit {
                Text("  ·  " + (appState.isPaid ? s.albumAtLimitPaid : s.albumAtLimitFree))
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.gold.opacity(0.78))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - 无照片空态

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            VStack(spacing: 20) {
                // 装饰插画
                ZStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColors.green.opacity(0.26))
                        .rotationEffect(.degrees(-32))
                        .offset(x: -54, y: 8)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.green.opacity(0.20))
                        .rotationEffect(.degrees(44))
                        .offset(x: 56, y: 18)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(AppColors.green.opacity(0.15))
                        .rotationEffect(.degrees(-8))
                        .offset(x: -40, y: -26)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.green.opacity(0.14))
                        .rotationEffect(.degrees(62))
                        .offset(x: 42, y: -22)
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundStyle(AppColors.muted.opacity(0.22))
                        .offset(x: 48, y: -28)
                    Image(systemName: "sparkle")
                        .font(.system(size: 7, weight: .ultraLight))
                        .foregroundStyle(AppColors.muted.opacity(0.17))
                        .offset(x: -50, y: 30)
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 58))
                        .foregroundStyle(AppColors.muted.opacity(0.17))
                }
                .frame(height: 106)

                VStack(spacing: 10) {
                    Text(s.albumEmptyTitle)
                        .font(AppFonts.serif(18, weight: .medium))
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Text(s.albumEmptyBody)
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.muted)
                        .multilineTextAlignment(.center)
                }

                if atLimit {
                    Button { showLimitSheet = true } label: {
                        Text(s.albumAddFirstBtn)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundStyle(AppColors.muted.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.muted.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                } else {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: remainingSlots,
                        matching: .images
                    ) {
                        Text(s.albumAddFirstBtn)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundStyle(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.greenDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                }

                Text(s.albumEmptyNote)
                    .font(AppFonts.body(12))
                    .foregroundStyle(AppColors.muted.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 照片网格

    private var photoGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
            spacing: 6
        ) {
            // 已有照片
            ForEach(albumPhotos) { photo in
                AlbumPhotoCell(photo: photo)
                    .onTapGesture { selectedPhoto = photo }
            }

            // 上传中占位卡片
            if isUploading {
                uploadingCell
            }

            // 继续添加卡片（未满且未上传时）
            if !atLimit && !isUploading {
                addMoreCell
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // 上传中卡片
    private var uploadingCell: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.white)
                        .shadow(color: .black.opacity(0.03), radius: 4)
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AppColors.green)
                        Text(s.albumUploadingLabel)
                            .font(AppFonts.body(11))
                            .foregroundStyle(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // 继续添加卡片
    private var addMoreCell: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: remainingSlots,
                    matching: .images
                ) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.white.opacity(0.65))
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(AppColors.muted.opacity(0.22))
                        VStack(spacing: 7) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(AppColors.muted.opacity(0.38))
                            Text(s.albumAddMore)
                                .font(AppFonts.body(11))
                                .foregroundStyle(AppColors.muted.opacity(0.45))
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 公开边界提示

    private var publicNotice: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.muted.opacity(0.44))
                .padding(.top, 1)
            Text(s.albumPublicNotice)
                .font(AppFonts.body(12))
                .foregroundStyle(AppColors.muted.opacity(0.50))
                .lineSpacing(3)
        }
    }

    // MARK: - 上传逻辑（不变）

    private func handleMultiUpload(items: [PhotosPickerItem]) {
        let total = items.count
        var succeeded = 0
        var failed = 0

        withAnimation { uploadState = .uploading(1, total) }

        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else {
                withAnimation { uploadState = .allFailed }
                autoDismiss(after: 4)
                return
            }

            for (index, item) in items.enumerated() {
                withAnimation { uploadState = .uploading(index + 1, total) }

                guard let rawData = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: rawData),
                      let jpegData = uiImage.jpegData(compressionQuality: 0.85) else {
                    failed += 1
                    continue
                }

                do {
                    let apiPhoto = try await APIClient.shared.uploadPhoto(
                        token: token, petId: petId, imageData: jpegData
                    )
                    let photo = Photo(
                        id: apiPhoto.id, petId: apiPhoto.petId,
                        userId: appState.currentUser?.id ?? "",
                        type: .album, url: apiPhoto.r2Url, thumbnailURL: apiPhoto.r2Url,
                        uploadStatus: .success, isMain: false,
                        sortOrder: apiPhoto.sortOrder, createdAt: apiPhoto.createdAt
                    )
                    appState.photos.append(photo)
                    succeeded += 1
                } catch {
                    print("uploadPhoto [\(index + 1)/\(total)] error: \(error)")
                    failed += 1
                }
            }

            withAnimation {
                if failed == 0 {
                    uploadState = .allSuccess(succeeded)
                } else if succeeded > 0 {
                    uploadState = .partial(succeeded, failed)
                } else {
                    uploadState = .allFailed
                }
            }
            autoDismiss(after: failed == 0 ? 2.5 : 4)
        }
    }

    private func autoDismiss(after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            withAnimation { uploadState = .idle }
        }
    }
}

// MARK: - 照片网格单元

private struct AlbumPhotoCell: View {
    let photo: Photo

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                AsyncImage(url: URL(string: photo.thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        AppColors.paperSoft
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColors.muted.opacity(0.35))
                            )
                    default:
                        AppColors.paperSoft
                            .overlay(ProgressView().scaleEffect(0.65))
                    }
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .clipped()
    }
}

// MARK: - 额度提示 Sheet

private struct LimitSheet: View {
    let isPaid: Bool
    let limit: Int
    let onUpgrade: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.muted.opacity(0.3))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 12) {
                Text(ls.strings.limitSheetBody(isPaid, limit))
                    .font(AppFonts.body(15))
                    .foregroundStyle(AppColors.ink)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                if !isPaid {
                    Button { onUpgrade() } label: {
                        Text(ls.strings.explorePlan)
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundStyle(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.greenDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                Button { dismiss() } label: {
                    Text(ls.strings.limitSheetGotIt)
                        .font(AppFonts.body(15))
                        .foregroundStyle(AppColors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.line))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.paper.ignoresSafeArea())
        .presentationDetents([.fraction(0.38)])
        .presentationDragIndicator(.hidden)
    }
}
