import SwiftUI

enum AppColors {
    static let paper = Color(red: 0.969, green: 0.945, blue: 0.910)      // #f7f1e8
    static let paperSoft = Color(red: 0.984, green: 0.969, blue: 0.941)  // #fbf7f0
    static let ink = Color(red: 0.180, green: 0.169, blue: 0.153)        // #2e2b27
    static let muted = Color(red: 0.451, green: 0.427, blue: 0.392)      // #736d64
    static let green = Color(red: 0.494, green: 0.576, blue: 0.400)      // #7e9366
    static let greenDeep = Color(red: 0.322, green: 0.404, blue: 0.267)  // #526744
    static let blue = Color(red: 0.392, green: 0.529, blue: 0.627)       // #6487a0
    static let blueDeep = Color(red: 0.149, green: 0.204, blue: 0.286)   // #263449
    static let gold = Color(red: 0.741, green: 0.561, blue: 0.298)       // #bd8f4d
    static let rose = Color(red: 0.749, green: 0.490, blue: 0.447)       // #bf7d72
    static let white = Color(red: 1.0, green: 0.992, blue: 0.980)        // #fffdfa
    static let line = Color(red: 0.271, green: 0.231, blue: 0.176).opacity(0.14)
}

enum AppFonts {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
