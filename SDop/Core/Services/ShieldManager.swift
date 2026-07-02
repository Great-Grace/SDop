import Foundation
import SwiftUI

// MARK: - ShieldManager (데모 모드)
// FamilyControls entitlement 승인 후 시스템 차단 기능 추가 예정
// 현재는 타이머 기반 사용 시간 추적 + UI 간섭만 구현

@MainActor
final class ShieldManager: ObservableObject {

    static let shared = ShieldManager()

    /// 차단 활성화 여부
    @Published var isShieldActive: Bool = false

    /// 독서 챌린지를 보여줘야 하는지 (앱 간섭 트리거)
    @Published var shouldShowChallenge: Bool = false

    /// 현재 "실행" 중인 앱 이름
    @Published var currentTargetApp: String?

    /// 잠금 해제 후 남은 시간 (초)
    @Published var remainingUnlockTime: TimeInterval = 0

    /// 현재 차단 대상 앱 정보
    private var targetApps: [(name: String, bundleId: String)] = []

    /// 타이머
    private var usageTimer: Timer?
    private var unlockTimer: Timer?
    private var currentUsageTime: TimeInterval = 0

    /// 챌린지 간격 (초) — 이 시간마다 챌린지 등장
    var challengeInterval: TimeInterval = 30 * 60

    private init() {}

    // MARK: - 차단 시작/중지

    /// 대상 앱 설정 및 차단 시작
    func applyShield(apps: [(name: String, bundleId: String)]) {
        guard !apps.isEmpty else { return }
        targetApps = apps
        isShieldActive = true
        startUsageTracking()
        print("[ShieldManager] 차단 시작 - \(apps.count)개 앱")
    }

    /// 모든 차단 해제
    func removeShield() {
        isShieldActive = false
        shouldShowChallenge = false
        currentTargetApp = nil
        targetApps.removeAll()
        stopUsageTracking()
        stopUnlockTimer()
        print("[ShieldManager] 차단 해제")
    }

    /// 챌린지 통과 후 임시 해제
    func temporaryUnlock(duration: TimeInterval) {
        shouldShowChallenge = false
        remainingUnlockTime = duration
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
        print("[ShieldManager] 임시 해제 - \(Int(duration / 60))분")
    }

    // MARK: - 사용 시간 추적

    private func startUsageTracking() {
        currentUsageTime = 0
        stopUsageTracking()

        usageTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isShieldActive else { return }
                guard self.remainingUnlockTime <= 0 else { return }

                self.currentUsageTime += 1

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

    /// 챌린지 트리거
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
        triggerChallenge()
        print("[ShieldManager] 잠금 해제 만료 — 챌린지 재등장")
    }

    // MARK: - 앱 실행 시뮬레이션

    /// 데모: 특정 앱 "실행"
    func simulateAppLaunch(appName: String) {
        guard isShieldActive else { return }
        currentTargetApp = appName

        if remainingUnlockTime <= 0 {
            shouldShowChallenge = true
            print("[ShieldManager] \(appName) 실행 → 챌린지 표시")
        } else {
            print("[ShieldManager] \(appName) 실행 → 잠금 해제 중 (\(Int(remainingUnlockTime))초 남음)")
        }
    }

    /// 모든 설정 초기화
    func clearAllSettings() {
        removeShield()
        print("[ShieldManager] 모든 설정 초기화")
    }
}
