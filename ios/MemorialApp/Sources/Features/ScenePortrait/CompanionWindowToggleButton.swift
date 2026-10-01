import SwiftUI

// "陪我一会儿" / "结束陪伴" toggle, shown next to ScenePortraitRevertButton
// whenever the pet has a dynamic observation video. First tap ever shows
// CompanionWindowIntroSheet; afterwards it starts/stops Picture in Picture
// directly. Styled as the primary (solid greenDeep) action, matching the
// PRD's "use Pawlight's current primary green action style" requirement —
// ScenePortraitRevertButton next to it keeps its existing lighter/secondary
// look unchanged.
struct CompanionWindowToggleButton: View {
    @EnvironmentObject var pip: CompanionWindowPiPController
    @EnvironmentObject var ls: LanguageStore
    @State private var showIntroSheet = false
    @State private var showStartFailedAlert = false
    @State private var showNotReadyAlert = false

    private var s: Strings { ls.strings }

    // While PiP is supported but not yet possible (controller just attached,
    // player item not ready yet), dim and disable instead of letting the tap
    // through to a "not ready" error — isPossible is KVO-driven and flips on
    // its own moments later, so there's nothing for the user to retry. A
    // device that doesn't support PiP at all has nothing to wait for, so it
    // keeps the button live and reports that immediately on tap instead.
    private var isPreparing: Bool { !pip.isActive && pip.isSupported && !pip.isPossible }

    var body: some View {
        Button {
            if pip.isActive {
                pip.stop()
                return
            }
            guard pip.isPossible else {
                showNotReadyAlert = true
                return
            }
            if pip.hasSeenIntro {
                pip.start()
            } else {
                showIntroSheet = true
            }
        } label: {
            Text(pip.isActive ? s.companionWindowStopBtn : s.companionWindowStartBtn)
                .font(AppFonts.body(12, weight: .medium))
                .foregroundColor(AppColors.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.greenDeep)
                .clipShape(Capsule())
                .opacity(isPreparing ? 0.5 : 1.0)
        }
        .disabled(isPreparing)
        .sheet(isPresented: $showIntroSheet) {
            CompanionWindowIntroSheet(onStart: { pip.start() })
        }
        .onChange(of: pip.startFailure) { _, failed in
            showStartFailedAlert = failed
        }
        .alert(s.companionWindowStartFailedTitle, isPresented: $showStartFailedAlert) {
            Button(s.ok, role: .cancel) { pip.acknowledgeStartFailure() }
        } message: {
            Text(s.companionWindowStartFailedBody)
        }
        .alert(s.companionWindowNotReadyTitle, isPresented: $showNotReadyAlert) {
            Button(s.ok, role: .cancel) {}
        } message: {
            Text(s.companionWindowNotReadyBody)
        }
    }
}
