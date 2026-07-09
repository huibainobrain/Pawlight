import SwiftUI

// Hiding the system back button with .navigationBarBackButtonHidden(true) does not
// disable the edge-swipe-to-go-back gesture — it stays live underneath the custom
// back button these onboarding screens use. A PhotosPicker sheet interaction near the
// left edge can conflict with that gesture recognizer and leave the pushed view
// stuck mid-transition (content shifted right, left edge clipped) instead of settling
// back into place. This disables the interactive pop gesture while the view is on
// screen and restores it when the view is popped or replaced.
private struct SwipeBackGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            uiViewController.parent?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

extension View {
    func disableSwipeBack() -> some View {
        background(SwipeBackGestureDisabler().frame(width: 0, height: 0))
    }
}
