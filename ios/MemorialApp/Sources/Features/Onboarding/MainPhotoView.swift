import SwiftUI
import PhotosUI

struct MainPhotoView: View {
    let petId: String
    let petName: String
    let petType: Pet.PetType

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var navigateToTier = false
    @State private var showExitAlert = false

    private var s: Strings { ls.strings }

    private var canContinue: Bool { selectedImage != nil && !isUploading }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {

                StepIndicator(current: 1, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // 标题区 + 氛围插画
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 0) {
                                Spacer()
                                MainPhotoAmbientElement()
                                    .padding(.trailing, -36)
                            }
                            .allowsHitTesting(false)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(s.mainPhotoStep)
                                    .font(AppFonts.body(12))
                                    .foregroundColor(AppColors.green)

                                Text(s.mainPhotoTitle)
                                    .font(AppFonts.serif(26, weight: .medium))
                                    .foregroundColor(AppColors.ink)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(s.mainPhotoBody(petName))
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                                    .padding(.trailing, 100)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 24)

                        // 照片选择区
                        photoPickerArea

                        if let error = uploadError {
                            Text(error)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.rose)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    // Forces a fresh layout pass when the PhotosPicker selection changes.
                    // The system picker sheet's dismissal has been seen to leave this
                    // ScrollView's content geometry (padding/safe-area resolution) stuck
                    // from before the sheet was presented — giving this subtree a new
                    // identity discards that stale state instead of reusing it.
                    .id(selectedImage == nil)
                }

                // 底部按钮
                VStack(spacing: 12) {
                    Button {
                        guard canContinue else { return }
                        uploadPhoto()
                    } label: {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView().tint(canContinue ? AppColors.white : AppColors.muted)
                            }
                            Text(isUploading ? s.uploading : s.next)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(canContinue ? AppColors.white : AppColors.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? AppColors.greenDeep.opacity(0.86) : AppColors.line)
                        .cornerRadius(14)
                        .shadow(
                            color: canContinue ? AppColors.greenDeep.opacity(0.10) : .clear,
                            radius: 8, x: 0, y: 3
                        )
                    }
                    .disabled(!canContinue)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if selectedImage != nil {
                        showExitAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 34, height: 34)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.ink)
                    }
                }
            }
        }
        .alert(s.mainPhotoExitTitle, isPresented: $showExitAlert) {
            Button(s.mainPhotoContinueUpload, role: .cancel) {}
            Button(s.leaveBtn, role: .destructive) { dismiss() }
        } message: {
            Text(s.mainPhotoExitBody)
        }
        .navigationDestination(isPresented: $navigateToTier) {
            TierSelectView(petName: petName, petType: petType)
        }
    }

    // Inlined to avoid Swift 6 @Binding isolation issue across struct boundary
    @ViewBuilder
    private var photoPickerArea: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let image = selectedImage {
                    // 已选择状态：大图预览 + 更换入口
                    ZStack(alignment: .bottom) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .medium))
                            Text(s.mainPhotoChange)
                                .font(AppFonts.body(13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.32))
                        .clipShape(Capsule())
                        .padding(.bottom, 16)
                    }
                } else {
                    // 未选择状态：虚线卡片
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)

                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AppColors.muted.opacity(0.20),
                                style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])
                            )

                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.green.opacity(0.09))
                                    .frame(width: 68, height: 68)
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 26))
                                    .foregroundColor(AppColors.green.opacity(0.65))
                            }
                            Text(s.mainPhotoPickLabel)
                                .font(AppFonts.body(15))
                                .foregroundColor(AppColors.muted.opacity(0.75))
                        }
                        .frame(height: 300)
                    }
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
            uploadError = s.mainPhotoProcessError
            return
        }
        isUploading = true
        uploadError = nil
        Task { @MainActor in
            do {
                try await appState.uploadMainPhoto(petId: petId, imageData: imageData)
                navigateToTier = true
            } catch {
                uploadError = s.mainPhotoUploadError
                print("uploadPhoto error: \(error)")
            }
            isUploading = false
        }
    }
}

// MARK: - 氛围插画元素

private struct MainPhotoAmbientElement: View {
    var body: some View {
        ZStack {
            // 背景光晕
            Circle()
                .fill(AppColors.green.opacity(0.055))
                .frame(width: 130, height: 130)

            // 主叶片
            MainPhotoLeaf()
                .fill(AppColors.green.opacity(0.22))
                .frame(width: 26, height: 42)
                .rotationEffect(.degrees(-18))
                .offset(x: -8, y: -18)

            MainPhotoLeaf()
                .fill(AppColors.green.opacity(0.15))
                .frame(width: 20, height: 34)
                .rotationEffect(.degrees(32))
                .offset(x: 16, y: -6)

            MainPhotoLeaf()
                .fill(AppColors.green.opacity(0.11))
                .frame(width: 16, height: 26)
                .rotationEffect(.degrees(-52))
                .offset(x: 6, y: 22)

            // 小草丘
            Ellipse()
                .fill(AppColors.green.opacity(0.12))
                .frame(width: 54, height: 18)
                .offset(x: 0, y: 38)

            // 星光点
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .ultraLight))
                .foregroundColor(AppColors.greenDeep.opacity(0.28))
                .offset(x: -32, y: -24)

            Circle()
                .fill(AppColors.muted.opacity(0.10))
                .frame(width: 4, height: 4)
                .offset(x: 34, y: 18)

            Circle()
                .fill(AppColors.green.opacity(0.14))
                .frame(width: 3, height: 3)
                .offset(x: -26, y: 30)
        }
        .frame(width: 130, height: 130)
    }
}

private struct MainPhotoLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.5, y: 0))
            p.addCurve(
                to: CGPoint(x: w * 0.5, y: h),
                control1: CGPoint(x: w, y: h * 0.25),
                control2: CGPoint(x: w, y: h * 0.75)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.5, y: 0),
                control1: CGPoint(x: 0, y: h * 0.75),
                control2: CGPoint(x: 0, y: h * 0.25)
            )
        }
    }
}
