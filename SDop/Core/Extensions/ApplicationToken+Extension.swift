import Foundation
#if canImport(FamilyControls)
import FamilyControls
#endif

// MARK: - ApplicationToken / DemoToken 타입 통합
// entitlement 없이도 빌드 가능하도록 조건부 컴파일

#if canImport(FamilyControls)
// 실기기: ApplicationToken 그대로 사용
typealias AppToken = ApplicationToken
#else
// 데모 모드: UUID 기반 가짜 토큰
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
#endif

// MARK: - 데모 모드 앱 목록 ( entitlement 없을 때 표시할 가상 앱들)

struct DemoApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let icon: String // SF Symbol name

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

// MARK: - ApplicationToken extensions (실기기 전용)

#if canImport(FamilyControls)
extension ApplicationToken {
    var debugDescription: String {
        "ApplicationToken(\(String(describing: self)))"
    }
}

extension Set where Element == ApplicationToken {
    var asArray: [ApplicationToken] { Array(self) }
}

extension Array where Element == ApplicationToken {
    var asSet: Set<ApplicationToken> { Set(self) }
}
#endif
