import SwiftUI

// A stable, named slot for a complex illustration that must NOT be hand-
// drawn in SwiftUI or scraped from the web (see the production asset
// checklist). `assetName` is the exact name a real image should be added
// under in Assets.xcassets — once that asset exists, this renders it
// automatically with no further code change anywhere that uses this view.
// Until then it renders a neutral placeholder so every screen still looks
// intentional, not broken.
struct PlanetLifeIllustrationSlot: View {
    let assetName: String
    let systemImageFallback: String
    var size: CGFloat = 72

    var body: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(AppColors.green.opacity(0.08))
                Image(systemName: systemImageFallback)
                    .font(.system(size: size * 0.38))
                    .foregroundColor(AppColors.green.opacity(0.32))
            }
            .frame(width: size, height: size)
        }
    }
}
