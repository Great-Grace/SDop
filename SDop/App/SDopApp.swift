import SwiftUI
import SwiftData
import FamilyControls

@main
struct SDopApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onAppear {
                    Task {
                        await appState.checkAuthorization()
                    }
                }
        }
        .modelContainer(for: [
            UserProfile.self,
            ReadingSession.self,
            TimeLimit.self
        ])
    }
}

// MARK: - Root View (handles onboarding vs main)
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Query private var profiles: [UserProfile]
    
    var body: some View {
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
                .tabItem {
                    Label("대시보드", systemImage: "chart.bar.fill")
                }
                .tag(Tab.dashboard)
            
            ContentLibraryView()
                .tabItem {
                    Label("도서관", systemImage: "books.vertical.fill")
                }
                .tag(Tab.library)
            
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color("AccentOrange"))
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var isOnboarding: Bool = false
    @Published var isAuthorized: Bool = false
    
    func checkAuthorization() async {
        ShieldManager.shared.checkAuthorizationStatus()
        isAuthorized = ShieldManager.shared.authorizationStatus == .approved
    }
    
    func requestAuthorization() async throws {
        try await ShieldManager.shared.requestAuthorization()
        isAuthorized = true
    }
    
    func completeOnboarding() {
        withAnimation(.spring(response: 0.6)) {
            isOnboarding = false
        }
    }
}
