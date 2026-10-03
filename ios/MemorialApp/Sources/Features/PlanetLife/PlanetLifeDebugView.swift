#if DEBUG
import SwiftUI

// "测试：模拟星球来信" — exercises the real business-state machine (enable,
// force-tick, read, bad-case) and the full Gift lifecycle (simulated
// purchase, since a real StoreKit sandbox purchase can't be scripted here)
// with zero real AI — every provider is 'fake' either way (see
// planet-life.module.ts). Reached from MineView's existing hidden dev-debug
// section; #if DEBUG means Release builds never see it either way.
struct PlanetLifeDebugView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var planetLife: PlanetLifeController
    @State private var isBusy = false
    @State private var log: [String] = []

    var body: some View {
        List {
            Section("星球生活") {
                Button("开启星球生活（调试）") { run { try await enable() } }
                Button("强制生成一条纪事（跳过等待）") { run { try await forceTick() } }
                Button("标记当前未读为已读") { run { try await markRead() } }
                Button("标记当前为「不像 TA」") { run { try await markBadCase() } }
            }
            Section("礼物") {
                Button("模拟购买「小球」") { run { try await simulatePurchase() } }
            }
            Section("真实生成") {
                Button("真实生成一次") { run { try await liveTrigger() } }
            }
            if !log.isEmpty {
                Section("结果") {
                    ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.system(size: 12, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("星球生活调试")
        .disabled(isBusy)
    }

    private func run(_ action: @escaping () async throws -> Void) {
        Task {
            isBusy = true
            defer { isBusy = false }
            do {
                try await action()
            } catch {
                append("❌ \(error.localizedDescription)")
            }
        }
    }

    private func append(_ line: String) {
        log.insert(line, at: 0)
    }

    private var context: (token: String, petId: String)? {
        guard let token = KeychainHelper.loadToken(), let petId = appState.currentPet?.id else { return nil }
        return (token, petId)
    }

    private func enable() async throws {
        guard let ctx = context else { return append("❌ 没有登录或没有宠物") }
        let ok = await planetLife.enable(token: ctx.token, petId: ctx.petId, notifyOnNewEvent: true)
        append(ok ? "✅ 已开启星球生活" : "❌ 开启失败：\(planetLife.lastErrorCode ?? "unknown")")
    }

    private func forceTick() async throws {
        guard let ctx = context else { return append("❌ 没有登录或没有宠物") }
        switch await planetLife.debugFakeTrigger(token: ctx.token, petId: ctx.petId) {
        case .success(let status):
            if let unread = status.unread {
                append("✅ 生成了一条新纪事：\(unread.title)")
            } else {
                append("ℹ️ 本次没有产生新内容（可能已有未读 / 还没开启 / 已达每周上限）")
            }
        case .failure(let failure):
            append("❌ 强制生成失败：\(failure.code)")
        }
    }

    private func markRead() async throws {
        guard let ctx = context, let unread = planetLife.status?.unread else {
            return append("ℹ️ 当前没有未读纪事")
        }
        let result = await planetLife.markRead(token: ctx.token, petId: ctx.petId, eventId: unread.id)
        append(result != nil ? "✅ 已标记为已读" : "❌ 标记失败")
    }

    private func markBadCase() async throws {
        guard let ctx = context else { return append("❌ 没有登录或没有宠物") }
        let target = planetLife.status?.unread ?? planetLife.events.first
        guard let event = target else { return append("ℹ️ 没有可标记的纪事") }
        let ok = await planetLife.markBadCase(token: ctx.token, petId: ctx.petId, eventId: event.id)
        append(ok ? "✅ 已标记「不像 TA」" : "❌ 标记失败")
    }

    private func simulatePurchase() async throws {
        guard let ctx = context else { return append("❌ 没有登录或没有宠物") }
        switch await planetLife.debugSimulatePurchase(token: ctx.token, petId: ctx.petId, giftAssetKey: "ball") {
        case .success(let instance):
            append("✅ 已模拟购买「小球」，实例状态：\(instance.status)")
        case .failure(let failure):
            append("❌ 模拟购买失败：\(failure.code)")
        }
    }

    private func liveTrigger() async throws {
        guard let ctx = context else { return append("❌ 没有登录或没有宠物") }
        switch await planetLife.debugLiveTrigger(token: ctx.token, petId: ctx.petId) {
        case .success:
            append("✅ 真实生成已触发")
        case .failure(let failure) where failure.code == "AI_PROVIDER_NOT_CONFIGURED":
            let missing = failure.missingProviders
            append("⚠️ AI Provider 尚未配置\(missing.isEmpty ? "" : "：\(missing.joined(separator: "、"))")")
        case .failure(let failure):
            append("❌ \(failure.code)")
        }
    }
}
#endif
