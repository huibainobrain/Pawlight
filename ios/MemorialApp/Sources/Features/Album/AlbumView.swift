import SwiftUI
import PhotosUI

struct AlbumView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showLimitAlert = false

    private var albumPhotos: [Photo] { appState.photos.filter { $0.type == .album } }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(albumPhotos.count) / \(appState.photoLimit) 张")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                        Spacer()
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                            Label("添加照片", systemImage: "plus")
                                .font(AppFonts.body(14, weight: .medium))
                                .foregroundColor(AppColors.greenDeep)
                        }
                        .disabled(!appState.canUploadPhoto)
                        .simultaneousGesture(TapGesture().onEnded {
                            if !appState.canUploadPhoto { showLimitAlert = true }
                        })
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if albumPhotos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.green.opacity(0.4))
                            Text("放一张TA的照片吧")
                                .font(AppFonts.body(15))
                                .foregroundColor(AppColors.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 2
                        ) {
                            ForEach(albumPhotos) { photo in
                                AsyncImage(url: URL(string: photo.thumbnailURL)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    AppColors.line.overlay(ProgressView())
                                }
                                .frame(height: 120)
                                .clipped()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("照片回忆")
        .navigationBarTitleDisplayMode(.inline)
        .alert("照片已达上限", isPresented: $showLimitAlert) {
            Button("了解完整纪念空间", role: .none) {}
            Button("取消", role: .cancel) {}
        } message: {
            Text(appState.isPaid ? "已达 50 张上限。" : "免费档最多保存 9 张照片，开启完整纪念空间可保存至 50 张。")
        }
    }
}
