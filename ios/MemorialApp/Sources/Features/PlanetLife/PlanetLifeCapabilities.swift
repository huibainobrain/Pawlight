import Foundation

// Single gate for Push-dependent Production UI. No Push infrastructure exists
// yet (this round's audit explicitly scopes that out) — Production must not
// offer a notification capability it cannot fulfill, so every Push-facing UI
// element (the enable-flow notify-ask stage, the settings "新记录提醒"
// toggle) checks this one flag instead of being deleted outright. Flipping it
// to true once real Push ships is the only change needed to bring that UI
// back; neither view needs restructuring. The underlying
// notifyOnNewEvent preference and its API already exist independently of
// this flag and are untouched (see PlanetLifeService.enable/updateSettings on
// the backend) — this only controls what Production shows.
enum PlanetLifeCapabilities {
    static let pushNotificationsAvailable = false
}
