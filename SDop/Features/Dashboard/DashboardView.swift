import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Query private var profiles: [UserProfile]
    @Query(sort: \ReadingSession.startTime, order: .reverse) private var sessions: [ReadingSession]
    @State private var isActive: Bool = true
    @State private var showChallenge = false
    
    private var profile: UserProfile? { profiles.first }
    
    private var todaySessions: [ReadingSession] {
        sessions.filter { Calendar.current.isDateInToday($0.startTime) }
    }
    
    private var todayPages: Int {
        todaySessions.reduce(0) { $0 + $1.pagesRead }
    }
    
    private var todayPassed: Int {
        todaySessions.filter { $0.passed }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    activeToggleCard
                    statsGrid
                    quickChallengeButton
                    shieldedAppsList
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Active Toggle
    private var activeToggleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isActive ? "SDop 활성" : "SDop 비활성")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text(isActive ? "앱 차단이 적용 중입니다" : "앱 차단이 해제되어 있습니다")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isActive)
                .tint(Color("AccentOrange"))
                .labelsHidden()
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        ShieldManager.shared.isShieldActive = true
                    } else {
                        ShieldManager.shared.removeShield()
                    }
                }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats
    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatCard(icon: "book.pages.fill", value: "\(todayPages)", label: "오늘 읽은 페이지")
            StatCard(icon: "flame.fill", value: "\(profile?.streakDays ?? 0)일", label: "연속 독서")
            StatCard(icon: "checkmark.circle.fill", value: "\(todayPassed)", label: "통과한 퀴즈")
        }
    }
    
    // MARK: - Quick Challenge
    private var quickChallengeButton: some View {
        Button { showChallenge = true } label: {
            HStack {
                Image(systemName: "book.fill").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("독서 챌린지 시작").font(.headline)
                    Text("지금 바로 읽고 시간을 얻으세요!")
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(Color("AccentOrange"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .fullScreenCover(isPresented: $showChallenge) {
            ReadingChallengeView(content: ContentService.shared.recommendedContent() ?? ContentService.shared.sampleContents().first!)
        }
    }
    
    // MARK: - Shielded Apps
    private var shieldedAppsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("차단된 앱")
                .font(.headline).foregroundStyle(.white)
            
            VStack(spacing: 8) {
                ShieldedAppRow(name: "Instagram", timeUsed: "23분", limit: "30분", isNearLimit: true)
                ShieldedAppRow(name: "YouTube", timeUsed: "1시간 10분", limit: "1시간", isNearLimit: false)
                ShieldedAppRow(name: "TikTok", timeUsed: "5분", limit: "30분", isNearLimit: true)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2).foregroundStyle(Color("AccentOrange"))
            Text(value)
                .font(.title3).fontWeight(.bold).foregroundStyle(.white)
            Text(label)
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Shielded App Row
struct ShieldedAppRow: View {
    let name: String
    let timeUsed: String
    let limit: String
    let isNearLimit: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundStyle(isNearLimit ? Color("AccentOrange") : .white.opacity(0.4))
            Text(name).font(.body).foregroundStyle(.white)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(timeUsed) / \(limit)")
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(isNearLimit ? Color("AccentOrange") : .white.opacity(0.6))
                if isNearLimit {
                    Text("거의 도달")
                        .font(.caption2).foregroundStyle(Color("AccentOrange"))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
