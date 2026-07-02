import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Query private var profiles: [UserProfile]
    @State private var showResetAlert = false
    
    private var profile: UserProfile? { profiles.first }
    
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
                        settingsRow(icon: "clock.fill", title: "사용 시간 제한", subtitle: "30분 / 앱")
                    }
                    
                    NavigationLink {
                        UnlockDurationView()
                    } label: {
                        settingsRow(icon: "lock.open.fill", title: "해제 지속 시간", subtitle: "퀴즈 통과 후 30분")
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Content
                Section("콘텐츠") {
                    NavigationLink {
                        ContentPreferencesView()
                    } label: {
                        settingsRow(icon: "book.fill", title: "독서 선호 설정", subtitle: "한국 고전")
                    }
                    
                    NavigationLink {
                        QuizDifficultyView()
                    } label: {
                        settingsRow(icon: "brain.head.profile", title: "퀴즈 난이도", subtitle: "보통")
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
                Button("초기화", role: .destructive) { appState.isOnboarding = true }
            } message: {
                Text("모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
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
    @State private var selectedApps: Set<String> = ["Instagram", "YouTube", "TikTok"]
    let allApps = ["Instagram", "YouTube", "TikTok", "X (Twitter)", "Facebook", "Netflix", "카카오톡", "네이버", "쿠팡", "당근"]
    
    var body: some View {
        List {
            Section {
                Text("차단할 앱을 선택하세요 (최대 5개)")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            .listRowBackground(Color.black)
            
            Section {
                ForEach(allApps, id: \.self) { app in
                    Button {
                        if selectedApps.contains(app) { selectedApps.remove(app) }
                        else if selectedApps.count < 5 { selectedApps.insert(app) }
                    } label: {
                        HStack {
                            Text(app).foregroundStyle(.white)
                            Spacer()
                            if selectedApps.contains(app) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("대상 앱 관리")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct TimeLimitsView: View {
    @State private var dailyLimit: Int = 30
    
    var body: some View {
        List {
            Section("일일 사용 제한") {
                ForEach([15, 30, 60, 120], id: \.self) { min in
                    Button { dailyLimit = min } label: {
                        HStack {
                            Text("\(min)분").foregroundStyle(.white)
                            Spacer()
                            if dailyLimit == min {
                                Image(systemName: "checkmark").foregroundStyle(Color("AccentOrange"))
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            Section {
                Text("설정한 시간이 지나면 해당 앱에 차단막이 표시됩니다.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .listRowBackground(Color.black)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("사용 시간 제한")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct UnlockDurationView: View {
    @State private var duration: Int = 30
    
    var body: some View {
        List {
            Section("퀴즈 통과 후 해제 시간") {
                ForEach([15, 30, 60, 120], id: \.self) { min in
                    Button { duration = min } label: {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("해제 지속 시간")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ContentPreferencesView: View {
    @State private var selectedCategories: Set<ContentCategory> = [.koreanClassic]
    
    var body: some View {
        List {
            Section("선호하는 콘텐츠 카테고리") {
                ForEach(ContentCategory.allCases, id: \.self) { category in
                    Button {
                        if selectedCategories.contains(category) { selectedCategories.remove(category) }
                        else { selectedCategories.insert(category) }
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("독서 선호 설정")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct QuizDifficultyView: View {
    @State private var difficulty: Difficulty = .medium
    
    var body: some View {
        List {
            Section("퀴즈 난이도") {
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    Button { difficulty = diff } label: {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("퀴즈 난이도")
        .toolbarColorScheme(.dark, for: .navigationBar)
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
