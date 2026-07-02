import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var shieldManager: ShieldManager
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
                    demoModeBanner
                    activeToggleCard
                    statsGrid
                    quickChallengeButton
                    if shieldManager.isShieldActive {
                        demoAppLauncher
                    }
                    shieldedAppsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
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

    private var activeToggleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(isActive ? "SDop 활성화" : "SDop 비활성화")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text(isActive ? "도파민 디톡스가 진행 중입니다" : "앱 접근 제한이 해제되었습니다")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Toggle("", isOn: $isActive)
                .tint(Color("AccentOrange"))
                .labelsHidden()
                .scaleEffect(1.1)
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        let apps = profile?.selectedAppNames.enumerated().map { i, name in
                            (name: name, bundleId: profile?.selectedAppBundleIds[i] ?? "")
                        } ?? []
                        shieldManager.applyShield(apps: apps)
                    } else {
                        shieldManager.removeShield()
                    }
                }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                if isActive {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(colors: [Color("AccentOrange").opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                }
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
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
            ReadingChallengeView(content: ContentService.shared.recommendedContent() ?? ContentService.shared.sampleContents().first ?? ReadingContent(id: UUID(), title: "샘플", author: "SDop", category: .koreanClassic, pages: [Page(pageNumber: 1, content: "샘플 콘텐츠입니다.")], quiz: [QuizQuestion(id: UUID(), question: "퀴즈", options: ["A", "B", "C", "D"], correctIndex: 0, explanation: "해설")], difficulty: .easy, coverImageName: nil))
        }
    }

    // MARK: - Demo App Launcher
    private var demoAppLauncher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("앱 실행 시뮬레이션")
                .font(.headline).foregroundStyle(.white)
            Text("아래 버튼을 눌러 앱을 \"실행\"하면 챌린지가 나타납니다")
                .font(.caption).foregroundStyle(.white.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(filteredDemoApps) { app in
                    Button {
                        shieldManager.simulateAppLaunch(appName: app.name)
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

            // 선택된 앱이 없으면 전체 프리셋 표시
            if filteredDemoApps.isEmpty {
                Text("온보딩에서 앱을 선택했는지 확인하세요")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    /// 프로필에 선택된 앱만 필터링, 없으면 전체 프리셋
    private var filteredDemoApps: [DemoApp] {
        guard let profile else { return DemoApp.presets }
        let selected = profile.selectedAppBundleIds
        if selected.isEmpty { return DemoApp.presets }
        return DemoApp.presets.filter { selected.contains($0.bundleId) }
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
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2).foregroundStyle(Color("AccentOrange"))
                .padding(12)
                .background(Color("AccentOrange").opacity(0.15))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3).fontWeight(.heavy).foregroundStyle(.white)
                Text(label)
                    .font(.caption).fontWeight(.medium).foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
