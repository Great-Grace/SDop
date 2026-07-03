import SwiftUI
import SwiftData

struct ReadingChallengeView: View {
    let content: ReadingContent
    var onComplete: ((Double, Bool) -> Void)? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var readingStartTime: Date = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showQuiz = false
    
    let minimumReadTime: TimeInterval = 300 // 5 minutes
    
    private var totalPages: Int { content.pages.count }
    private var progress: Double { totalPages > 0 ? Double(currentPage + 1) / Double(totalPages) : 0 }
    private var hasReadEnoughTime: Bool { elapsedTime >= minimumReadTime }
    private var hasReadAllPages: Bool { currentPage >= totalPages - 1 }
    private var canFinish: Bool { hasReadEnoughTime && hasReadAllPages }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        bookHeader
                        pageContent
                        pageIndicator
                    }
                    .padding(20)
                }
                
                bottomBar
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("독서 챌린지")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .fullScreenCover(isPresented: $showQuiz) {
                QuizView(questions: content.quiz) { score, passed in
                    if passed {
                        saveSession(score: score, passed: true)
                        onComplete?(score, passed)
                        dismiss()
                    } else {
                        showQuiz = false
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("AccentOrange"))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("\(currentPage + 1) / \(totalPages) 페이지")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(hasReadEnoughTime ? .green : Color("AccentOrange"))
                if !hasReadEnoughTime {
                    Text("(최소 \(Int((minimumReadTime - elapsedTime) / 60))분)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Book Header
    private var bookHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(content.title)
                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
            Text(content.author)
                .font(.subheadline).foregroundStyle(.white.opacity(0.5))
            Divider().background(Color.white.opacity(0.1))
        }
    }
    
    // MARK: - Page Content
    private var pageContent: some View {
        Group {
            if content.pages.indices.contains(currentPage) {
                Text(content.pages[currentPage].content)
            } else {
                Text("콘텐츠를 불러올 수 없습니다.")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
            .font(.system(.body, design: .serif))
            .foregroundStyle(Color(white: 0.85))
            .lineSpacing(10)
            .tracking(0.3)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack {
            if currentPage > 0 {
                Button { withAnimation { currentPage -= 1 } } label: {
                    Label("이전", systemImage: "chevron.left")
                        .font(.subheadline).foregroundStyle(Color("AccentOrange"))
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                ForEach(0..<min(totalPages, 10), id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color("AccentOrange") : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
                if totalPages > 10 {
                    Text("...").foregroundStyle(.white.opacity(0.3))
                }
            }
            
            Spacer()
            
            if currentPage < totalPages - 1 {
                Button { withAnimation { currentPage += 1 } } label: {
                    Label("다음", systemImage: "chevron.right")
                        .font(.subheadline).foregroundStyle(Color("AccentOrange"))
                }
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if canFinish {
                Button { showQuiz = true } label: {
                    Text("퀴즈 시작하기")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color("AccentOrange"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                HStack {
                    Image(systemName: hasReadAllPages ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(hasReadAllPages ? .green : .white.opacity(0.3))
                    Text("모든 페이지 읽음")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: hasReadEnoughTime ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(hasReadEnoughTime ? .green : .white.opacity(0.3))
                    Text("최소 시간 경과")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Timer
    private var formattedTime: String {
        let m = Int(elapsedTime) / 60, s = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func startTimer() {
        stopTimer()
        readingStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsedTime = Date().timeIntervalSince(self.readingStartTime)
            }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); timer = nil }
    
    private func saveSession(score: Double, passed: Bool) {
        let session = ReadingSession(contentId: content.id, pagesRead: totalPages)
        session.startTime = readingStartTime
        session.endTime = Date()
        session.quizScore = score
        session.passed = passed
        modelContext.insert(session)
        
        if let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
            profile.recordReading(pages: totalPages)
        } else {
            // Profile fetch failed — log in debug, session is still saved
            #if DEBUG
            print("[ReadingChallengeView] UserProfile fetch failed")
            #endif
        }
    }
}
