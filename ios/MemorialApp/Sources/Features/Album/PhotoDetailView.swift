import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showDeleteError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                AsyncImage(url: URL(string: photo.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.4))
                            Text("照片加载失败")
                                .font(AppFonts.body(14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    default:
                        ProgressView().tint(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        if isDeleting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(AppColors.rose)
                        }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .alert("要删除这张照片吗？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { performDelete() }
        } message: {
            Text("删除后，这张照片将不再出现在TA的照片回忆和分享出去的纪念页中。")
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("这张照片暂时没能删除，请稍后再试。")
        }
    }

    private func performDelete() {
        isDeleting = true
        Task { @MainActor in
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else {
                isDeleting = false
                showDeleteError = true
                return
            }
            do {
                try await APIClient.shared.deletePhoto(token: token, petId: petId, photoId: photo.id)
                appState.photos.removeAll { $0.id == photo.id }
                dismiss()
            } catch {
                print("deletePhoto error: \(error)")
                isDeleting = false
                showDeleteError = true
            }
        }
    }
}
