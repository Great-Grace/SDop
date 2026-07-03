import SwiftUI
import SwiftData

@main
struct SDopApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var shieldManager = ShieldManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(shieldManager)
                .onAppear {
                    appState.checkAuthorization()
                }
        }
        .modelContainer(for: [
            UserProfile.self,
            ReadingSession.self,
            TimeLimit.self
        ])
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var shieldManager: ShieldManager
    @Query private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            Group {
                if appState.isOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
            .tint(Color("AccentOrange"))
            .animation(.easeInOut, value: appState.isOnboarding)
            .onAppear {
                if profiles.isEmpty {
                    appState.isOnboarding = true
                }
            }

            // 챌린지 오버레이 — 시간 초과 시 전체화면 간섭
            if shieldManager.shouldShowChallenge {
                ChallengeOverlay()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }
}

// MARK: - 챌린지 오버레이
struct ChallengeOverlay: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var showReading = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("AccentOrange"))

                VStack(spacing: 12) {
                    Text("도파민을 원하면 책임을 져라!")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(.white)

                    if let app = shieldManager.currentTargetApp {
                        Text("\(app) 사용 시간이 초과되었습니다")
                            .font(.subheadline)
                            .foregroundStyle(Color("AccentOrange"))
                    }

                    Text("앱을 사용하려면 먼저 독서 챌린지를\n완료해야 합니다")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Button {
                    showReading = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("책 읽고 해제하기")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color("AccentOrange"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showReading) {
            ReadingChallengeView(
                content: ContentService.shared.recommendedContent()
                    ?? ContentService.shared.sampleContents().first
                    ?? ReadingContent(id: UUID(), title: "샘플", author: "SDop", category: .koreanClassic, pages: [Page(pageNumber: 1, content: "샘플 콘텐츠입니다.")], quiz: [QuizQuestion(id: UUID(), question: "퀴즈", options: ["A", "B", "C", "D"], correctIndex: 0, explanation: "해설")], difficulty: .easy, coverImageName: nil)
            ) { _, passed in
                if passed {
                    shieldManager.temporaryUnlock(duration: 30 * 60)
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String {
        case dashboard, library, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("대시보드", systemImage: "chart.bar.fill") }
                .tag(Tab.dashboard)

            ContentLibraryView()
                .tabItem { Label("도서관", systemImage: "books.vertical.fill") }
                .tag(Tab.library)

            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Color("AccentOrange"))
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var isOnboarding: Bool = false
    @Published var isAuthorized: Bool = true

    func checkAuthorization() {
        // 데모 모드: 인증 불필요
    }

    func completeOnboarding() {
        withAnimation(.spring(response: 0.6)) {
            isOnboarding = false
        }
    }
}
