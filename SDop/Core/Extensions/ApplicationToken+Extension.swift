import Foundation
import FamilyControls

// MARK: - ApplicationToken extensions
// ApplicationToken already conforms to Hashable, Equatable, Codable, and Sendable
// since iOS 16.0. No @retroactive conformances are needed.

// MARK: - Debug description

extension ApplicationToken {
    
    /// 토큰의 문자열 표현 (디버그용)
    var debugDescription: String {
        "ApplicationToken(\(String(describing: self)))"
    }
}

// MARK: - Set<ApplicationToken> 확장

extension Set where Element == ApplicationToken {
    
    /// 토큰 집합을 ApplicationToken 배열로 변환 (SwiftData 배열 필드용)
    var asArray: [ApplicationToken] {
        Array(self)
    }
}

extension Array where Element == ApplicationToken {
    
    /// 토큰 배열을 Set으로 변환 (중복 제거)
    var asSet: Set<ApplicationToken> {
        Set(self)
    }
}
