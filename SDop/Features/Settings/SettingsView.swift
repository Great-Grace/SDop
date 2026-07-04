import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var shieldManager: ShieldManager
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showResetAlert = false
    
    private var profile: UserProfile? { profiles.first }
    
    // Read persisted preferences for display
    @AppStorage("selectedDifficulty") private var selectedDifficulty: String = Difficulty.medium.rawValue
    @AppStorage("selectedCategories") private var selectedCategoriesRaw: String = ContentCategory.koreanClassic.rawValue
    @AppStorage("unlockDurationMinutes") private var unlockDurationMinutes: Int = 30
    
    private var currentDifficulty: Difficulty {
        Difficulty(rawValue: selectedDifficulty) ?? .medium
    }
    
    private var categoriesDisplay: String {
        let raws = selectedCategoriesRaw.components(separatedBy: ",")
        let names = raws.compactMap { ContentCategory(rawValue: $0)?.displayName }
        return names.isEmpty ? "한국 고전" : names.joined(separator: ", ")
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("AccentOrange"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SDop 사용자")
                                .font(.headline).foregroundStyle(.white)
                            Text("활성 상태: \(profile?.isActive == true ? "ON" : "OFF")")
                                .font(.caption).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                
                // Target Apps
                Section("차단 대상 앱") {
                    NavigationLink {
                        TargetAppsView()
                    } label: {
                        settingsRow(icon: "apps.iphone", title: "대상 앱 관리", subtitle: "\(profile?.selectedAppCount ?? 0)개 앱 선택됨")
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Time Settings
                Section("시간 설정") {
                    NavigationLink {
                        TimeLimitsView()
                    } label: {
                        settingsRow(icon: "clock.fill", title: "챌린지 간격", subtitle: "\(Int(shieldManager.challengeInterval / 60))분")
                    }
                    
                    NavigationLink {
                        UnlockDurationView()
                    } label: {
                        settingsRow(icon: "lock.open.fill", title: "해제 지속 시간", subtitle: "퀴즈 통과 후 \(unlockDurationMinutes)분")
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Content
                Section("콘텐츠") {
                    NavigationLink {
                        ContentPreferencesView()
                    } label: {
                        settingsRow(icon: "book.fill", title: "독서 선호 설정", subtitle: categoriesDisplay)
                    }
                    
                    NavigationLink {
                        QuizDifficultyView()
                    } label: {
                        settingsRow(icon: "brain.head.profile", title: "퀴즈 난이도", subtitle: currentDifficulty.displayName)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Stats
                Section("통계") {
                    settingsRow(icon: "chart.bar.fill", title: "총 읽은 페이지", subtitle: "\(profile?.totalReadingPages ?? 0)쪽")
                    settingsRow(icon: "flame.fill", title: "연속 독서 기록", subtitle: "\(profile?.streakDays ?? 0)일")
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // About
                Section("정보") {
                    NavigationLink { AboutView() } label: {
                        settingsRow(icon: "info.circle.fill", title: "SDop 소개", subtitle: "v1.0.0")
                    }
                    
                    if let privacyURL = URL(string: "https://sdop.app/privacy") {
                    Link(destination: privacyURL) {
                        settingsRow(icon: "hand.raised.fill", title: "개인정보 처리방침", subtitle: nil)
                    }
                    }
                    
                    if let termsURL = URL(string: "https://sdop.app/terms") {
                    Link(destination: termsURL) {
                        settingsRow(icon: "doc.text.fill", title: "이용약관", subtitle: nil)
                    }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Danger
                Section {
                    Button {
                        showResetAlert = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("데이터 초기화", isPresented: $showResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
    
    private func resetAllData() {
        // Delete all SwiftData objects
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: ReadingSession.self)
            try modelContext.delete(model: TimeLimit.self)
        } catch {
#if DEBUG
            print("[SettingsView] 데이터 초기화 실패: \(error)")
#endif
        }
        // Clear persisted preferences
        UserDefaults.standard.removeObject(forKey: "selectedDifficulty")
        UserDefaults.standard.removeObject(forKey: "selectedCategories")
        UserDefaults.standard.removeObject(forKey: "unlockDurationMinutes")
        // Reset ShieldManager
        ShieldManager.shared.clearAllSettings()
        // Return to onboarding
        appState.isOnboarding = true
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body).foregroundStyle(Color("AccentOrange"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Sub-views

struct TargetAppsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @EnvironmentObject var shieldManager: ShieldManager
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        List {
            Section {
                let maxApps = profile?.isPremium == true ? "무제한" : "최대 3개"
                Text("차단할 앱을 선택하세요 (\(maxApps))")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                if profile?.isPremium != true && (profile?.selectedAppCount ?? 0) >= 3 {
                    Text("무료 버전은 최대 3개까지 선택 가능합니다")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .listRowBackground(Color.black)
            
            Section {
                ForEach(DemoApp.presets) { app in
                    Button {
                        toggleApp(app)
                    } label: {
                        HStack {
                            Image(systemName: app.icon)
                                .foregroundStyle(isAppSelected(app) ? Color("AccentOrange") : .white.opacity(0.6))
                                .frame(width: 28)
                            Text(app.name).foregroundStyle(.white)
                            Spacer()
                            if isAppSelected(app) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                    .disabled(!isAppSelected(app) && !(profile?.canAddMoreApps ?? false))
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("대상 앱 관리")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func isAppSelected(_ app: DemoApp) -> Bool {
        profile?.selectedAppBundleIds.contains(app.bundleId) ?? false
    }
    
    private func toggleApp(_ app: DemoApp) {
        guard let profile else { return }
        
        if isAppSelected(app) {
            profile.removeApp(bundleId: app.bundleId)
        } else {
            profile.addApp(name: app.name, bundleId: app.bundleId)
        }
        
        // Update ShieldManager with new app list
        let selectedApps = DemoApp.presets.filter { app in
            profile.selectedAppBundleIds.contains(app.bundleId)
        }
        let shieldApps = selectedApps.map { (name: $0.name, bundleId: $0.bundleId) }
        shieldManager.applyShield(apps: shieldApps)
    }
}

struct TimeLimitsView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    
    private let options = [15, 30, 60, 120]
    
    var body: some View {
        List {
            Section("챌린지 간격") {
                ForEach(options, id: \.self) { min in
                    Button {
                        shieldManager.challengeInterval = TimeInterval(min * 60)
                    } label: {
                        HStack {
                            Text("\(min)분").foregroundStyle(.white)
                            Spacer()
                            if Int(shieldManager.challengeInterval / 60) == min {
                                Image(systemName: "checkmark").foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            Section {
                Text("설정한 시간이 지나면 독서 챌린지가 나타납니다.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .listRowBackground(Color.black)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("챌린지 간격")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct UnlockDurationView: View {
    @AppStorage("unlockDurationMinutes") private var duration: Int = 30
    
    private let options = [15, 30, 60, 120]
    
    var body: some View {
        List {
            Section("퀴즈 통과 후 해제 시간") {
                ForEach(options, id: \.self) { min in
                    Button {
                        duration = min
                    } label: {
                        HStack {
                            Text("\(min)분").foregroundStyle(.white)
                            Spacer()
                            if duration == min {
                                Image(systemName: "checkmark").foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            Section {
                Text("퀴즈를 통과하면 설정한 시간 동안 앱을 사용할 수 있습니다.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .listRowBackground(Color.black)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("해제 지속 시간")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ContentPreferencesView: View {
    @AppStorage("selectedCategories") private var selectedCategoriesRaw: String = ContentCategory.koreanClassic.rawValue
    
    @State private var selectedCategories: Set<ContentCategory> = []
    
    var body: some View {
        List {
            Section("선호하는 콘텐츠 카테고리") {
                ForEach(ContentCategory.allCases, id: \.self) { category in
                    Button {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                        persistCategories()
                    } label: {
                        HStack {
                            Label(category.displayName, systemImage: category.icon)
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            Section {
                Text("선택한 카테고리의 콘텐츠가 우선 표시됩니다.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .listRowBackground(Color.black)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("독서 선호 설정")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        let raws = selectedCategoriesRaw.components(separatedBy: ",")
        selectedCategories = Set(raws.compactMap { ContentCategory(rawValue: $0) })
        if selectedCategories.isEmpty {
            selectedCategories = [.koreanClassic]
        }
    }
    
    private func persistCategories() {
        let raw = selectedCategories.map { $0.rawValue }.joined(separator: ",")
        selectedCategoriesRaw = raw
    }
}

struct QuizDifficultyView: View {
    @AppStorage("selectedDifficulty") private var selectedDifficultyRaw: String = Difficulty.medium.rawValue
    
    @State private var difficulty: Difficulty = .medium
    
    var body: some View {
        List {
            Section("퀴즈 난이도") {
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    Button {
                        difficulty = diff
                        selectedDifficultyRaw = diff.rawValue
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(diff.displayName).foregroundStyle(.white)
                                Text(diffDescription(diff))
                                    .font(.caption).foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            if difficulty == diff {
                                Image(systemName: "checkmark").foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            Section {
                Text("난이도에 따라 퀴즈의 깊이와 통과 기준이 달라집니다.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .listRowBackground(Color.black)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("퀴즈 난이도")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            difficulty = Difficulty(rawValue: selectedDifficultyRaw) ?? .medium
        }
    }
    
    private func diffDescription(_ diff: Difficulty) -> String {
        switch diff {
        case .easy: return "기본 개념 위주, 60% 통과"
        case .medium: return "상세 내용 포함, 70% 통과"
        case .hard: return "깊이 있는 이해 필요, 80% 통과"
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("AccentOrange"))
                    .padding(.top, 32)
                
                VStack(spacing: 4) {
                    Text("SDop!")
                        .font(.title).fontWeight(.bold)
                        .foregroundStyle(Color("AccentOrange"))
                    Text("Stop Dopamine")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    Text("v1.0.0")
                        .font(.caption).foregroundStyle(.white.opacity(0.4))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("SDop은 무분별한 스마트폰 사용을 줄이고, 건전한 독서 습관을 기르기 위해 만들어졌습니다.")
                        .font(.body).foregroundStyle(.white.opacity(0.8)).lineSpacing(6)
                    Text("도파민을 원하면, 그에 따른 책임을 져라!")
                        .font(.headline).foregroundStyle(Color("AccentOrange"))
                    Text("앱 사용 시간을 설정하면, 제한 시간이 되면 책을 읽고 퀴즈를 풀어야 앱을 사용할 수 있습니다.")
                        .font(.body).foregroundStyle(.white.opacity(0.8)).lineSpacing(6)
                }
                .padding(20)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                
                Text("Made with ❤️ in Korea")
                    .font(.caption).foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 32)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("SDop 소개")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
