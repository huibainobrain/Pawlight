import SwiftUI
import PhotosUI

private enum UploadBannerState: Equatable {
    case idle, uploading, success, failure, formatError
}

struct AlbumView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var uploadState: UploadBannerState = .idle
    @State private var showLimitSheet = false
    @State private var wantsEntitlement = false
    @State private var showEntitlement = false
    @State private var selectedPhoto: Photo? = nil

    private var albumPhotos: [Photo] {
        appState.photos.filter { $0.type == .album }
            .sorted { $0.createdAt < $1.createdAt }
    }
    private var count: Int { albumPhotos.count }
    private var limit: Int { appState.photoLimit }
    private var atLimit: Bool { count >= limit }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                if uploadState != .idle {
                    uploadBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        capacityRow
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if albumPhotos.isEmpty {
                            emptyStateView
                        } else {
                            photoGridView
                        }

                        publicNotice
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: uploadState)
        .navigationTitle("照片回忆")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                toolbarButton
            }
        }
        .onChange(of: selectedItems) { _, items in
            guard let item = items.first else { return }
            selectedItems = []
            handleUpload(item: item)
        }
        .sheet(isPresented: $showLimitSheet, onDismiss: {
            if wantsEntitlement {
                wantsEntitlement = false
                showEntitlement = true
            }
        }) {
            LimitSheet(isPaid: appState.isPaid, limit: limit, onUpgrade: {
                wantsEntitlement = true
                showLimitSheet = false
            })
        }
        .navigationDestination(isPresented: $showEntitlement) {
            EntitlementView()
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo).environmentObject(appState)
        }
    }

    // MARK: Toolbar

    @ViewBuilder private var toolbarButton: some View {
        if uploadState == .uploading {
            ProgressView().scaleEffect(0.8)
        } else if atLimit {
            Button("添加照片") { showLimitSheet = true }
                .foregroundColor(AppColors.muted)
        } else {
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                Text("添加照片")
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.greenDeep)
            }
        }
    }

    // MARK: Capacity Row

    @ViewBuilder private var capacityRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("已保存 \(count) / \(limit) 张")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.muted)
            if atLimit {
                Text(appState.isPaid ? "已到当前照片上限" : "已到免费照片上限")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: Empty State

    @ViewBuilder private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 52)
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 52))
                    .foregroundColor(AppColors.green.opacity(0.35))

                VStack(spacing: 10) {
                    Text("把和TA有关的瞬间\n慢慢放在这里")
                        .font(AppFonts.serif(18, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                    Text("可以先从一张最想留下的照片开始。")
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                }

                Text("主照片会陪TA出现在星球里。\n这里可以继续放下更多和TA有关的瞬间。")
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.muted.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)

                if atLimit {
                    Button { showLimitSheet = true } label: {
                        Text("添加第一张照片")
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.line))
                    }
                    .padding(.horizontal, 32)
                } else {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                        Text("添加第一张照片")
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.greenDeep)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 32)
                }
            }
            Spacer(minLength: 52)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Photo Grid

    @ViewBuilder private var photoGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ],
            spacing: 2
        ) {
            ForEach(albumPhotos) { photo in
                Button { selectedPhoto = photo } label: {
                    AsyncImage(url: URL(string: photo.thumbnailURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            AppColors.line
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppColors.muted.opacity(0.4))
                                )
                        default:
                            AppColors.line
                                .overlay(ProgressView().scaleEffect(0.7))
                        }
                    }
                    .frame(height: 120)
                    .clipped()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    // MARK: Public Notice

    @ViewBuilder private var publicNotice: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundColor(AppColors.muted.opacity(0.5))
                .padding(.top, 1)
            Text("这些照片会出现在TA的纪念主页里。分享纪念页时，也记得TA的人可以看到。")
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.muted.opacity(0.5))
                .lineSpacing(3)
        }
    }

    // MARK: Upload Banner

    @ViewBuilder private var uploadBanner: some View {
        let (message, bg) = bannerContent
        HStack(spacing: 8) {
            if uploadState == .uploading {
                ProgressView()
                    .scaleEffect(0.75)
                    .tint(.white)
            }
            Text(message)
                .font(AppFonts.body(13))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(bg)
    }

    private var bannerContent: (String, Color) {
        switch uploadState {
        case .uploading:   return ("正在保存照片……", AppColors.ink.opacity(0.85))
        case .success:     return ("照片已放进回忆里。", AppColors.greenDeep)
        case .failure:     return ("这张照片暂时没能保存，请重新试一次。", AppColors.rose)
        case .formatError: return ("V1暂时只支持图片上传，视频回忆会在后续版本考虑。", AppColors.rose)
        case .idle:        return ("", .clear)
        }
    }

    // MARK: Upload Logic

    private func handleUpload(item: PhotosPickerItem) {
        withAnimation { uploadState = .uploading }
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else {
                withAnimation { uploadState = .failure }
                autoDismiss(after: 4)
                return
            }
            guard let rawData = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: rawData),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.85) else {
                withAnimation { uploadState = .formatError }
                autoDismiss(after: 3)
                return
            }
            do {
                let apiPhoto = try await APIClient.shared.uploadPhoto(token: token, petId: petId, imageData: jpegData)
                let photo = Photo(
                    id: apiPhoto.id, petId: apiPhoto.petId,
                    userId: appState.currentUser?.id ?? "",
                    type: .album, url: apiPhoto.r2Url, thumbnailURL: apiPhoto.r2Url,
                    uploadStatus: .success, isMain: false,
                    sortOrder: apiPhoto.sortOrder, createdAt: apiPhoto.createdAt
                )
                appState.photos.append(photo)
                withAnimation { uploadState = .success }
                autoDismiss(after: 2)
            } catch {
                print("uploadAlbumPhoto error: \(error)")
                withAnimation { uploadState = .failure }
                autoDismiss(after: 4)
            }
        }
    }

    private func autoDismiss(after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            withAnimation { uploadState = .idle }
        }
    }
}

// MARK: - 额度提示 Sheet

private struct LimitSheet: View {
    let isPaid: Bool
    let limit: Int
    let onUpgrade: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.muted.opacity(0.3))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 12) {
                Text(isPaid ? "当前照片数量已达上限。" : "免费纪念空间最多可保存 \(limit) 张照片。\n如果还想继续留下更多瞬间，可以了解完整纪念空间。")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                if !isPaid {
                    Button {
                        onUpgrade()
                    } label: {
                        Text("了解完整纪念空间")
                            .font(AppFonts.body(15, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.greenDeep)
                            .cornerRadius(10)
                    }
                }
                Button { dismiss() } label: {
                    Text("知道了")
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.white)
                        .cornerRadius(10)
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
