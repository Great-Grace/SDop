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
                    if true { // 데모 모드 배너 (entitlement 승인 후 제거)
                        demoModeBanner
                    }
                    activeToggleCard
                    statsGrid
                    quickChallengeButton
                    if ShieldManager.shared.isShieldActive {
                        demoAppLauncher
                    }
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

    // MARK: - Demo Mode Banner
    private var demoModeBanner: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color("AccentOrange"))
            Text("데모 모드 — 실제 앱 차단은 entitlement 승인 후 활성화됩니다")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color("AccentOrange").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Active Toggle
    private var activeToggleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isActive ? "SDop 활성" : "SDop 비활성")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text(isActive ? "앱 간섭이 적용 중입니다" : "앱 간섭이 해제되어 있습니다")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isActive)
                .tint(Color("AccentOrange"))
                .labelsHidden()
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        let apps = profile?.selectedAppNames.enumerated().map { i, name in
                            (name: name, bundleId: profile?.selectedAppBundleIds[i] ?? "")
                        } ?? []
                        ShieldManager.shared.applyShield(apps: apps)
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

    // MARK: - Demo App Launcher (데모 모드 전용)
    private var demoAppLauncher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("앱 실행 시뮬레이션")
                .font(.headline).foregroundStyle(.white)
            Text("아래 버튼을 눌러 앱을 \"실행\"하면 챌린지가 나타납니다")
                .font(.caption).foregroundStyle(.white.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(DemoApp.presets.filter { app in
                    profile?.selectedAppBundleIds.contains(app.bundleId) ?? false
                }) { app in
                    Button {
                        ShieldManager.shared.simulateAppLaunch(appName: app.name)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: app.icon)
                                .font(.title2)
                                .foregroundStyle(Color("AccentOrange"))
                            Text(app.name)
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Shielded Apps
    private var shieldedAppsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("간섭 대상 앱")
                .font(.headline).foregroundStyle(.white)

            if let profile, !profile.selectedAppNames.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(profile.selectedAppNames.enumerated()), id: \.offset) { _, name in
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color("AccentOrange"))
                            Text(name).font(.body).foregroundStyle(.white)
                            Spacer()
                            Text("간섭 대상")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                Text("설정에서 앱을 추가하세요")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
