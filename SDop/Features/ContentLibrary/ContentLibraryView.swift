import SwiftUI

struct ContentLibraryView: View {
    @State private var contents: [ReadingContent] = []
    @State private var selectedCategory: ContentCategory? = nil
    @State private var searchText: String = ""
    @State private var selectedContent: ReadingContent? = nil
    
    private var filteredContents: [ReadingContent] {
        var results = contents
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            results = results.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        return results
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoryFilter
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredContents) { content in
                            BookCard(content: content)
                                .onTapGesture { selectedContent = content }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
            .background(Color.black.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "제목, 작가 검색...")
            .navigationTitle("도서관")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedContent) { content in
                BookDetailView(content: content)
            }
            .onAppear {
                if contents.isEmpty {
                    contents = ContentService.shared.loadAllContents()
                }
            }
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(label: "전체", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ContentCategory.allCases, id: \.self) { category in
                    CategoryChip(label: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? Color("AccentOrange") : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Book Card
struct BookCard: View {
    let content: ReadingContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentOrange").opacity(0.3), Color("AccentOrange").opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 160)
                
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color("AccentOrange"))
                    Image(systemName: content.category.icon)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(content.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white).lineLimit(2)
                Text(content.author)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5)).lineLimit(1)
            }
            
            HStack {
                Label("\(content.pageCount)쪽", systemImage: "doc.text")
                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(content.difficulty.displayName)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var difficultyColor: Color {
        switch content.difficulty {
        case .easy: return .green
        case .medium: return Color("AccentOrange")
        case .hard: return .red
        }
    }
}

// MARK: - Book Detail View
struct BookDetailView: View {
    let content: ReadingContent
    @Environment(\.dismiss) private var dismiss
    @State private var startReading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    infoSection
                    descriptionSection
                    quizInfoSection
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("도서 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button { startReading = true } label: {
                    Text("독서 시작")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color("AccentOrange"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
            }
            .fullScreenCover(isPresented: $startReading) {
                ReadingChallengeView(content: content)
            }
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color("AccentOrange").opacity(0.4), Color("AccentOrange").opacity(0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 140)
                .overlay(Image(systemName: "book.closed.fill").font(.title).foregroundStyle(Color("AccentOrange")))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(content.title)
                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                Text(content.author)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 8) {
                    Text(content.category.displayName)
                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color("AccentOrange").opacity(0.2))
                        .clipShape(Capsule()).foregroundStyle(Color("AccentOrange"))
                    Text(content.difficulty.displayName)
                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule()).foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var infoSection: some View {
        HStack(spacing: 0) {
            infoItem(icon: "doc.text", value: "\(content.pageCount)", label: "페이지")
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            infoItem(icon: "clock", value: "\(content.estimatedReadingMinutes)분", label: "예상 시간")
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            infoItem(icon: "questionmark.circle", value: "\(content.quiz.count)", label: "퀴즈")
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func infoItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(Color("AccentOrange"))
            Text(value).font(.headline).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("작품 소개").font(.headline).foregroundStyle(.white)
            Text("이 작품은 한국 고전 문학의 대표작으로, 독서 챌린지를 통해 깊이 있는 이해를 할 수 있습니다. 퀴즈를 통과하면 제한된 앱을 일정 시간 사용할 수 있습니다.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6)).lineSpacing(6)
        }
    }
    
    private var quizInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("퀴즈 정보").font(.headline).foregroundStyle(.white)
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("60% 이상 맞춰야 통과").font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            HStack {
                Image(systemName: "questionmark.circle.fill").foregroundStyle(Color("AccentOrange"))
                Text("\(content.quiz.count)문제 객관식").font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
