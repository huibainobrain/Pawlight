import SwiftUI
import PhotosUI

struct MainPhotoView: View {
    let petId: String
    let petName: String
    let petType: Pet.PetType

    @EnvironmentObject var appState: AppState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var navigateToTier = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                StepIndicator(current: 1, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2 / 3  主照片")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                            Text("选一张最想看到TA的照片")
                                .font(AppFonts.serif(24, weight: .medium))
                                .foregroundColor(AppColors.ink)
                            Text("主照片会显示在首页、回忆页和分享页，\n是\(petName)的视觉锚点。")
                                .font(AppFonts.body(14))
                                .foregroundColor(AppColors.muted)
                                .lineSpacing(4)
                        }
                        .padding(.top, 28)

                        photoPickerArea

                        if let error = uploadError {
                            Text(error)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.rose)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Button {
                    uploadPhoto()
                } label: {
                    HStack(spacing: 8) {
                        if isUploading {
                            ProgressView().tint(AppColors.white)
                        }
                        Text(isUploading ? "上传中..." : "下一步")
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(selectedImage != nil && !isUploading ? AppColors.white : AppColors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedImage != nil && !isUploading ? AppColors.greenDeep : AppColors.line)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .disabled(selectedImage == nil || isUploading)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToTier) {
            TierSelectView(petName: petName, petType: petType)
        }
    }

    // Inlined to avoid Swift 6 @Binding isolation issue across struct boundary
    @ViewBuilder
    private var photoPickerArea: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.line, lineWidth: 1)
                    )

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.green.opacity(0.6))
                        Text("点击选择照片")
                            .font(AppFonts.body(15))
                            .foregroundColor(AppColors.muted)
                    }
                    .frame(height: 280)
                }
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task { @MainActor in
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    private func uploadPhoto() {
        guard let image = selectedImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            uploadError = "图片处理失败"
            return
        }
        isUploading = true
        uploadError = nil
        Task { @MainActor in
            do {
                try await appState.uploadMainPhoto(petId: petId, imageData: imageData)
                navigateToTier = true
            } catch {
                uploadError = "上传失败，请重试"
                print("uploadPhoto error: \(error)")
            }
            isUploading = false
        }
    }
}
