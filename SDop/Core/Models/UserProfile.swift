import Foundation
import SwiftData

// MARK: - 사용자 프로필 (SwiftData)

/// 앱의 핵심 데이터 모델 - 사용자 프로필, 읽기 세션, 시간 제한
@Model
final class UserProfile {
    /// 사용자 이름
    var name: String

    /// 차단 기능 활성화 여부
    var isActive: Bool

    /// 선택된 대상 앱 이름 목록 (데모 모드 호환)
    var selectedAppNames: [String]

    /// 선택된 대상 앱 번들ID 목록
    var selectedAppBundleIds: [String]

    /// 총 읽은 페이지 수
    var totalReadingPages: Int

    /// 연속 읽기 일수 (스트릭)
    var streakDays: Int

    /// 마지막 읽기 날짜
    var lastReadingDate: Date?

    /// 프리미엄 사용자 여부
    var isPremium: Bool

    /// 생성일
    var createdAt: Date

    /// 관계: 읽기 세션 목록
    @Relationship(deleteRule: .cascade)
    var readingSessions: [ReadingSession]?

    /// 관계: 시간 제한 설정 목록
    @Relationship(deleteRule: .cascade)
    var timeLimits: [TimeLimit]?

    init(
        name: String = "",
        isActive: Bool = false,
        isPremium: Bool = false
    ) {
        self.name = name
        self.isActive = isActive
        self.selectedAppNames = []
        self.selectedAppBundleIds = []
        self.totalReadingPages = 0
        self.streakDays = 0
        self.lastReadingDate = nil
        self.isPremium = isPremium
        self.createdAt = Date()
        self.readingSessions = []
        self.timeLimits = []
    }

    /// 오늘 이미 읽었는지 확인
    var hasReadToday: Bool {
        guard let lastDate = lastReadingDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// 스트릭 업데이트 - 읽기 완료 시 호출
    func recordReading(pages: Int) {
        totalReadingPages += pages

        if let lastDate = lastReadingDate,
           Calendar.current.isDateInYesterday(lastDate) {
            streakDays += 1
        } else if !hasReadToday {
            streakDays = 1
        }

        lastReadingDate = Date()
    }

    /// 선택된 앱 개수
    var selectedAppCount: Int {
        selectedAppNames.count
    }

    /// 무료 사용자 앱 선택 제한 (최대 3개)
    var canAddMoreApps: Bool {
        isPremium || selectedAppNames.count < 3
    }

    /// 앱 추가
    func addApp(name: String, bundleId: String) {
        guard canAddMoreApps else { return }
        guard !selectedAppBundleIds.contains(bundleId) else { return }
        selectedAppNames.append(name)
        selectedAppBundleIds.append(bundleId)
    }

    /// 앱 제거
    func removeApp(bundleId: String) {
        if let idx = selectedAppBundleIds.firstIndex(of: bundleId) {
            selectedAppBundleIds.remove(at: idx)
            selectedAppNames.remove(at: idx)
        }
    }
}

// MARK: - 읽기 세션

/// 하나의 읽기 세션을 기록하는 모델
@Model
final class ReadingSession {
    /// 읽은 콘텐츠의 ID
    var contentId: UUID

    /// 세션 시작 시간
    var startTime: Date

    /// 세션 종료 시간 (nil이면 진행 중)
    var endTime: Date?

    /// 읽은 페이지 수
    var pagesRead: Int

    /// 퀴즈 점수 (0.0 ~ 1.0)
    var quizScore: Double

    /// 퀴즈 통과 여부 (60% 이상)
    var passed: Bool

    /// 관계: 이 세션에 연결된 사용자 프로필
    var userProfile: UserProfile?

    init(contentId: UUID, pagesRead: Int = 0) {
        self.contentId = contentId
        self.startTime = Date()
        self.endTime = nil
        self.pagesRead = pagesRead
        self.quizScore = 0.0
        self.passed = false
    }

    /// 세션 완료 처리
    func complete(quizScore: Double) {
        self.endTime = Date()
        self.quizScore = quizScore
        self.passed = quizScore >= 0.6
    }

    /// 읽기 소요 시간 (초)
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    /// 읽기 소요 시간 (분) 표시용
    var durationMinutes: Int {
        guard let duration = duration else { return 0 }
        return Int(duration / 60)
    }
}

// MARK: - 시간 제한 설정

/// 앱별 시간 제한 설정
@Model
final class TimeLimit {
    /// 대상 앱 이름
    var appName: String

    /// 대상 앱 번들ID
    var appBundleId: String

    /// 일일 시간 제한 (초 단위)
    var dailyLimit: TimeInterval

    /// 차단 후 재도전 간격 (초 단위)
    var challengeInterval: TimeInterval

    /// 관계: 이 제한에 연결된 사용자 프로필
    var userProfile: UserProfile?

    init(
        appName: String,
        appBundleId: String,
        dailyLimit: TimeInterval = 30 * 60,
        challengeInterval: TimeInterval = 30 * 60
    ) {
        self.appName = appName
        self.appBundleId = appBundleId
        self.dailyLimit = dailyLimit
        self.challengeInterval = challengeInterval
    }

    /// 일일 제한 (분 단위 표시용)
    var dailyLimitMinutes: Int {
        Int(dailyLimit / 60)
    }

    /// 재도전 간격 (분 단위 표시용)
    var challengeIntervalMinutes: Int {
        Int(challengeInterval / 60)
    }
}
