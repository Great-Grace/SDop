import Foundation
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

// MARK: - ShieldManager
// 데모 모드: FamilyControls 없이도 동작 (UI + 타이머 기반)
// 실기기: FamilyControls + ManagedSettings로 시스템 레벨 차단

@MainActor
final class ShieldManager: ObservableObject {

    static let shared = ShieldManager()

    // MARK: - Published State

    /// 현재 차단이 활성화되어 있는지
    @Published var isShieldActive: Bool = false

    /// 데모 모드 여부 (entitlement 없을 때)
    @Published var isDemoMode: Bool = true

    /// 독서 챌린지를 보여줘야 하는지 (앱 간섭 트리거)
    @Published var shouldShowChallenge: Bool = false

    /// 현재 사용 중인 앱 이름 (데모 모드에서 표시용)
    @Published var currentTargetApp: String?

    /// 잠금 해제 후 남은 시간 (초)
    @Published var remainingUnlockTime: TimeInterval = 0

    // MARK: - Private State

    #if canImport(FamilyControls)
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    #endif

    /// 현재 차단 대상 앱 정보
    private var targetApps: [(name: String, bundleId: String)] = []

    /// 타이머 (시간 추적용)
    private var usageTimer: Timer?
    private var unlockTimer: Timer?
    private var currentUsageTime: TimeInterval = 0

    /// 잠금 해제 간격 (초) — 이 시간마다 챌린지 등장
    var challengeInterval: TimeInterval = 30 * 60 // 기본 30분

    private init() {
        #if canImport(FamilyControls)
        isDemoMode = false
        #else
        isDemoMode = true
        #endif
    }

    // MARK: - 인증

    #if canImport(FamilyControls)
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

    func checkAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }
    #else
    func checkAuthorizationStatus() {
        // 데모 모드: 항상 authorized
        print("[ShieldManager] 데모 모드 — 인증 불필요")
    }
    #endif

    // MARK: - Shield 적용/해제

    /// 대상 앱 설정 및 차단 시작
    func applyShield(apps: [(name: String, bundleId: String)]) {
        guard !apps.isEmpty else {
            print("[ShieldManager] 차단할 앱이 없습니다")
            return
        }

        targetApps = apps
        isShieldActive = true

        #if canImport(FamilyControls)
        // 실기기: ManagedSettings로 시스템 레벨 차단
        // TODO: ApplicationToken으로 변환하여 store.shield.applications에 설정
        print("[ShieldManager] 시스템 차단 적용 - \(apps.count)개 앱")
        #else
        print("[ShieldManager] 데모 모드 차단 시작 - \(apps.count)개 앱")
        #endif

        // 사용 시간 추적 시작
        startUsageTracking()
    }

    /// 모든 차단 해제
    func removeShield() {
        isShieldActive = false
        shouldShowChallenge = false
        currentTargetApp = nil
        targetApps.removeAll()

        #if canImport(FamilyControls)
        store.shield.applications = nil
        #endif

        stopUsageTracking()
        stopUnlockTimer()

        print("[ShieldManager] 차단 해제 완료")
    }

    /// 챌린지 통과 후 임시 해제
    /// - Parameter duration: 해제 유지 시간 (초)
    func temporaryUnlock(duration: TimeInterval) {
        shouldShowChallenge = false
        remainingUnlockTime = duration

        print("[ShieldManager] 임시 해제 - \(Int(duration / 60))분")

        // 남은 시간 카운트다운
        stopUnlockTimer()
        unlockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.remainingUnlockTime -= 1
                if self.remainingUnlockTime <= 0 {
                    self.onUnlockExpired()
                }
            }
        }
    }

    // MARK: - 사용 시간 추적

    private func startUsageTracking() {
        currentUsageTime = 0
        stopUsageTracking()

        // 1초마다 사용 시간 증가
        usageTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isShieldActive else { return }
                // 잠금 해제 중이면 시간 추적 안 함
                guard self.remainingUnlockTime <= 0 else { return }

                self.currentUsageTime += 1

                // 챌린지 간격 도달 시
                if self.currentUsageTime >= self.challengeInterval {
                    self.triggerChallenge()
                }
            }
        }
    }

    private func stopUsageTracking() {
        usageTimer?.invalidate()
        usageTimer = nil
        currentUsageTime = 0
    }

    private func stopUnlockTimer() {
        unlockTimer?.invalidate()
        unlockTimer = nil
        remainingUnlockTime = 0
    }

    /// 챌린지 트리거 — 앱 사용 중단하고 독서 강제
    private func triggerChallenge() {
        guard isShieldActive else { return }
        shouldShowChallenge = true
        currentUsageTime = 0
        print("[ShieldManager] 챌린지 트리거!")
    }

    /// 잠금 해제 만료
    private func onUnlockExpired() {
        stopUnlockTimer()
        remainingUnlockTime = 0
        // 해제 만료 → 다시 챌린지 표시
        triggerChallenge()
        print("[ShieldManager] 잠금 해제 만료 — 챌린지 재등장")
    }

    // MARK: - 데모 모드 시뮬레이션

    /// 데모 모드: 특정 앱 "실행" 시뮬레이션
    func simulateAppLaunch(appName: String) {
        guard isShieldActive else { return }
        currentTargetApp = appName

        if remainingUnlockTime <= 0 {
            // 잠금 상태 → 챌린지 표시
            shouldShowChallenge = true
            print("[ShieldManager] \(appName) 실행 → 챌린지 표시")
        } else {
            // 잠금 해제 상태 → 앱 사용 허용
            print("[ShieldManager] \(appName) 실행 → 잠금 해제 중 (\(Int(remainingUnlockTime))초 남음)")
        }
    }

    /// ManagedSettings 초기화
    func clearAllSettings() {
        #if canImport(FamilyControls)
        store.clearAllSettings()
        #endif
        removeShield()
        print("[ShieldManager] 모든 설정 초기화 완료")
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
