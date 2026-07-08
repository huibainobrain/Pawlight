import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showDeleteError = false

    private var s: Strings { ls.strings }

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
                                .foregroundColor(.white.opacity(0.35))
                            Text(s.photoLoadError)
                                .font(AppFonts.body(14))
                                .foregroundColor(.white.opacity(0.35))
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
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showDeleteConfirm = true } label: {
                        if isDeleting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.rose)
                                .frame(width: 36, height: 36)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .alert(s.photoDeleteTitle, isPresented: $showDeleteConfirm) {
            Button(s.cancel, role: .cancel) {}
            Button(s.delete, role: .destructive) { performDelete() }
        } message: {
            Text(s.photoDeleteBody)
        }
        .alert(s.photoDeleteErrorTitle, isPresented: $showDeleteError) {
            Button(s.ok, role: .cancel) {}
        } message: {
            Text(s.photoDeleteErrorBody)
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
