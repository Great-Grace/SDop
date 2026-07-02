import Foundation
import FamilyControls
import ManagedSettings

// MARK: - ShieldManager

/// FamilyControls 인증 및 ManagedSettings 차단(Shield) 적용을 관리하는 서비스
@MainActor
final class ShieldManager: ObservableObject {
    
    static let shared = ShieldManager()
    
    /// FamilyControls 인증 상태
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    /// 현재 차단이 활성화되어 있는지 여부
    @Published var isShieldActive: Bool = false
    
    /// FamilyControls 인증을 관리하는 객체
    private let center = AuthorizationCenter.shared
    
    /// ManagedSettings 스토어 - 앱 차단 설정을 적용하는 데 사용
    private let store = ManagedSettingsStore()
    
    /// 현재 차단 대상으로 설정된 앱 토큰들
    private var shieldedTokens: Set<ApplicationToken> = []
    
    private init() {}
    
    // MARK: - 인증
    
    /// FamilyControls 사용 권한을 요청한다
    /// iOS 설정 > 화면 사용 시간에서 사용자가 승인해야 함
    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            print("[ShieldManager] FamilyControls 인증 성공")
        } catch {
            authorizationStatus = .denied
            print("[ShieldManager] FamilyControls 인증 실패: \(error.localizedDescription)")
            throw ShieldError.authorizationFailed(error)
        }
    }
    
    /// 현재 인증 상태를 확인하고 갱신한다
    func checkAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }
    
    // MARK: - Shield 적용/해제
    
    /// 선택된 앱 토큰에 대해 차단(Shield)을 적용한다
    /// - Parameter tokens: 차단할 앱의 ApplicationToken 집합
    func applyShield(tokens: Set<ApplicationToken>) {
        guard authorizationStatus == .approved else {
            print("[ShieldManager] 인증되지 않은 상태에서 차단을 시도할 수 없습니다")
            return
        }
        
        guard !tokens.isEmpty else {
            print("[ShieldManager] 차단할 앱이 없습니다")
            return
        }
        
        shieldedTokens = tokens
        
        // ManagedSettings에 차단 설정 적용
        // applications: 차단할 앱 토큰 집합
        // 설정된 앱을 열면 시스템 Shield가 표시됨
        store.shield.applications = tokens
        isShieldActive = true
        
        print("[ShieldManager] 차단 적용 완료 - \(tokens.count)개 앱")
    }
    
    /// 모든 앱의 차단을 해제한다
    func removeShield() {
        store.shield.applications = nil
        shieldedTokens.removeAll()
        isShieldActive = false
        
        print("[ShieldManager] 차단 해제 완료")
    }
    
    /// 특정 앱의 차단만 해제한다 (일시 해제용)
    /// - Parameter token: 차단 해제할 앱의 토큰
    func removeShield(for token: ApplicationToken) {
        shieldedTokens.remove(token)
        
        if shieldedTokens.isEmpty {
            removeShield()
        } else {
            store.shield.applications = shieldedTokens
        }
        
        print("[ShieldManager] 특정 앱 차단 해제 완료")
    }
    
    /// 임시로 모든 차단을 해제하고, 지정된 시간 후 다시 적용한다
    /// - Parameters:
    ///   - duration: 차단 해제 유지 시간 (초)
    ///   - tokens: 다시 적용할 앱 토큰들
    func temporaryUnlock(duration: TimeInterval, tokens: Set<ApplicationToken>) {
        removeShield()
        
        print("[ShieldManager] 임시 해제 - \(Int(duration / 60))분 후 재적용")
        
        // 지정된 시간 후 차단 재적용
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            // 인증 상태가 유효한 경우에만 재적용
            guard self.authorizationStatus == .approved else { return }
            
            self.applyShield(tokens: tokens)
            print("[ShieldManager] 임시 해제 만료 - 차단 재적용")
        }
    }
    
    /// 현재 차단 대상 애플리케이션 토큰 목록 반환
    func currentShieldedTokens() -> Set<ApplicationToken> {
        return shieldedTokens
    }
    
    /// ManagedSettings 스토어의 모든 설정을 초기화한다
    func clearAllSettings() {
        store.clearAllSettings()
        shieldedTokens.removeAll()
        isShieldActive = false
        
        print("[ShieldManager] 모든 ManagedSettings 초기화 완료")
    }
}

// MARK: - 에러 정의

enum ShieldError: LocalizedError {
    case authorizationFailed(Error)
    case notAuthorized
    case noTokensProvided
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let error):
            return "FamilyControls 인증 실패: \(error.localizedDescription)"
        case .notAuthorized:
            return "FamilyControls 인증이 필요합니다"
        case .noTokensProvided:
            return "차단할 앱이 지정되지 않았습니다"
        }
    }
}
