import SwiftUI
import SwiftData

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: Step = .welcome

    enum Step: Int, CaseIterable {
        case welcome = 0
        case concept
        case selectApps
        case setLimits
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color.black],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()

            VStack {
                // Progress
                ProgressView(value: Double(currentStep.rawValue), total: Double(Step.allCases.count - 1))
                    .tint(Color("AccentOrange"))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                TabView(selection: $currentStep) {
                    welcomeStep.tag(Step.welcome)
                    conceptStep.tag(Step.concept)
                    selectAppsStep.tag(Step.selectApps)
                    setLimitsStep.tag(Step.setLimits)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
            }
        }
    }

    // MARK: - Welcome
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(colors: [Color("AccentOrange"), .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.pulse)
                .shadow(color: Color("AccentOrange").opacity(0.4), radius: 20)

            VStack(spacing: 12) {
                Text("SDop!")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom)
                    )

                Text("STOP DOPAMINE")
                    .font(.headline).fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(3)
            }

            Text("도파민을 원하면,\n그에 따른 책임을 져라.")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .lineSpacing(8)

            Spacer()

            nextButton("시작하기") { currentStep = .concept }
        }
    }

    // MARK: - Concept
    private var conceptStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                conceptRow(icon: "hourglass", title: "시간 제한 설정", desc: "인스타그램, 유튜브 등\n사용 시간을 설정하세요")
                conceptRow(icon: "book.fill", title: "책을 읽어라", desc: "제한 시간이 되면\n독서 챌린지가 시작됩니다")
                conceptRow(icon: "checkmark.seal.fill", title: "퀴즈 풀기", desc: "읽은 내용을 확인하는\n퀴즈를 통과해야 해제!")
            }
            .padding(.horizontal, 32)

            Spacer()

            nextButton("다음") { currentStep = .selectApps }
        }
    }

    private func conceptRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color("AccentOrange"))
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(desc).font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Select Apps
    @State private var selectedAppIds: Set<UUID> = []

    private var selectAppsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("제한할 앱 선택")
                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                Text("이 앱을 열면 독서 챌린지가 먼저 나타납니다")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(DemoApp.presets) { app in
                        AppSelectionCard(
                            name: app.name,
                            icon: app.icon,
                            isSelected: selectedAppIds.contains(app.id)
                        ) {
                            if selectedAppIds.contains(app.id) {
                                selectedAppIds.remove(app.id)
                            } else if selectedAppIds.count < 3 {
                                selectedAppIds.insert(app.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            nextButton("다음 (\(selectedAppIds.count)개 선택)") { currentStep = .setLimits }
                .disabled(selectedAppIds.isEmpty)
                .opacity(selectedAppIds.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Set Limits
    @State private var selectedMinutes: Int = 30

    private var setLimitsStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("챌린지 간격 설정")
                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                Text("이 시간마다 독서 챌린지가 다시 나타납니다")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 16) {
                Text("\(selectedMinutes)분")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Color("AccentOrange"))

                HStack(spacing: 12) {
                    ForEach([15, 30, 60, 120], id: \.self) { min in
                        Button { selectedMinutes = min } label: {
                            Text("\(min)분")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(selectedMinutes == min ? .white : Color("AccentOrange"))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(selectedMinutes == min ? Color("AccentOrange") : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("AccentOrange"), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            Spacer()

            Button {
                saveProfile()
                appState.completeOnboarding()
            } label: {
                Text("설정 완료!")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("AccentOrange"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32).padding(.bottom, 48)
        }
    }

    // MARK: - Helpers
    private func nextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("AccentOrange"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 32).padding(.bottom, 48)
    }

    private func saveProfile() {
        let profile = UserProfile(
            name: "",
            isActive: true,
            isPremium: false
        )

        // 선택된 앱 정보 저장
        let selectedApps = DemoApp.presets.filter { selectedAppIds.contains($0.id) }
        for app in selectedApps {
            profile.addApp(name: app.name, bundleId: app.bundleId)
        }

        modelContext.insert(profile)

        // ShieldManager에 간섭 간격 설정
        ShieldManager.shared.challengeInterval = TimeInterval(selectedMinutes * 60)

        // 차단 시작
        let apps = selectedApps.map { (name: $0.name, bundleId: $0.bundleId) }
        ShieldManager.shared.applyShield(apps: apps)
    }
}

// MARK: - App Selection Card
struct AppSelectionCard: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color("AccentOrange").opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 72, height: 72)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color("AccentOrange"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .offset(x: 8, y: -8)
                    }

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color("AccentOrange") : .white.opacity(0.6))
                }

                Text(name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                    .lineLimit(1)
            }
        }
    }
}
