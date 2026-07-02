import Foundation

// MARK: - AppToken (데모 모드 전용)
// FamilyControls entitlement 승인 후 ApplicationToken으로 교체 예정

struct AppToken: Hashable, Codable, Identifiable {
    let id: UUID
    let bundleIdentifier: String
    let displayName: String

    init(bundleIdentifier: String, displayName: String) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

// MARK: - 데모 모드 앱 목록

struct DemoApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let icon: String

    static let presets: [DemoApp] = [
        DemoApp(name: "Instagram", bundleId: "com.burbn.instagram", icon: "camera.fill"),
        DemoApp(name: "YouTube", bundleId: "com.google.ios.youtube", icon: "play.rectangle.fill"),
        DemoApp(name: "TikTok", bundleId: "com.zhiliaoapp.musically", icon: "music.note"),
        DemoApp(name: "Facebook", bundleId: "com.facebook.Facebook", icon: "person.2.fill"),
        DemoApp(name: "X (Twitter)", bundleId: "com.atebits.Tweetie2", icon: "bubble.left.and.bubble.right.fill"),
        DemoApp(name: "카카오톡", bundleId: "com.kakao.talk", icon: "message.fill"),
        DemoApp(name: "넷플릭스", bundleId: "com.netflix.Netflix", icon: "film.fill"),
        DemoApp(name: "디스코드", bundleId: "com.hackinc.discord", icon: "headphones"),
    ]
}
