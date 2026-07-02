import Foundation
import FamilyControls

// MARK: - ApplicationToken 확장

/// ApplicationToken은 기본적으로 Identifiable, Hashable, Codable을 지원하지 않으므로
/// SwiftData 저장 및 SwiftUI List 사용을 위한 확장을 추가한다.
extension ApplicationToken: @retroactive Hashable {
    
    public func hash(into hasher: inout Hasher) {
        // ApplicationToken은 내부적으로 Equatable을 준수하므로
        // 고유 식별자로 사용 가능한 데이터 변환 후 해싱
        hasher.combine(self.description)
    }
}

extension ApplicationToken: @retroactive Equatable {
    
    public static func == (lhs: ApplicationToken, rhs: ApplicationToken) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: - Codable 확장 (SwiftData 저장용)

/// ApplicationToken을 JSON으로 직렬화/역직렬화할 수 있도록 지원
/// SwiftData에서 [ApplicationToken] 배열을 저장하는 데 필요
extension ApplicationToken: @retroactive Codable {
    
    enum CodingKeys: String, CodingKey {
        case tokenData
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .tokenData)
        
        // NSKeyedUnarchiver를 사용하여 ApplicationToken 복원
        guard let token = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ApplicationToken.self,
            from: data
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .tokenData,
                in: container,
                debugDescription: "ApplicationToken 복원 실패"
            )
        }
        self = token
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // NSKeyedArchiver를 사용하여 ApplicationToken을 Data로 변환
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: self,
            requiringSecureCoding: true
        )
        try container.encode(data, forKey: .tokenData)
    }
}

// MARK: - 디버그/표시용 확장

extension ApplicationToken {
    
    /// 토큰의 문자열 표현 (디버그용)
    var debugDescription: String {
        "ApplicationToken(\(self.description))"
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
