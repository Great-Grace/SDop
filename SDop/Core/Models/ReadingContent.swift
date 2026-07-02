import Foundation

// MARK: - 읽기 콘텐츠 모델

/// 읽기 콘텐츠 (책, 기사 등) 의 전체 정보를 담는 모델
struct ReadingContent: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String           // 예: "춘향전 - 제1장"
    let author: String          // 예: "작자 미상"
    let category: ContentCategory
    let pages: [Page]           // 10-20 페이지 분량
    let quiz: [QuizQuestion]    // 이해도 퀴즈 3-5문제
    let difficulty: Difficulty
    let coverImageName: String? // 에셋 이미지 이름 (옵션)
    
    /// 전체 페이지 수
    var pageCount: Int { pages.count }
    
    /// 예상 읽기 시간 (분) - 분당 약 400단어 기준
    var estimatedReadingMinutes: Int {
        let totalWords = pages.reduce(0) { $0 + $1.wordCount }
        return max(1, totalWords / 400)
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReadingContent, rhs: ReadingContent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 페이지

/// 하나의 페이지를 나타내는 모델
struct Page: Codable, Identifiable {
    var id: Int { pageNumber }
    let pageNumber: Int
    let content: String         // 평문, 페이지당 약 500단어
    
    /// 대략적인 단어 수 (한국어는 공백 기준 분리)
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - 퀴즈 문제

/// 이해도 확인 퀴즈 문제
struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let options: [String]       // 4지선다
    let correctIndex: Int       // 정답 인덱스 (0-3)
    let explanation: String     // 정답 해설
    
    /// 정답 텍스트 반환
    var correctAnswer: String {
        guard options.indices.contains(correctIndex) else { return "" }
        return options[correctIndex]
    }
    
    /// 주어진 인덱스가 정답인지 확인
    func isCorrect(_ index: Int) -> Bool {
        index == correctIndex
    }
}

// MARK: - 콘텐츠 카테고리

/// 읽기 콘텐츠의 카테고리 분류
enum ContentCategory: String, Codable, CaseIterable {
    case koreanClassic  = "korean_classic"  // 한국 고전 문학
    case news           = "news"            // 뉴스 기사
    case english        = "english"         // 영어 학습
    case educational    = "educational"     // 교육 콘텐츠
    case essay          = "essay"           // 에세이
    case science        = "science"         // 과학
    
    var displayName: String {
        switch self {
        case .koreanClassic: return "한국 고전"
        case .news:          return "뉴스"
        case .english:       return "영어 학습"
        case .educational:   return "교육"
        case .essay:         return "에세이"
        case .science:       return "과학"
        }
    }
    
    var icon: String {
        switch self {
        case .koreanClassic: return "book.closed"
        case .news:          return "newspaper"
        case .english:       return "text.book.closed"
        case .educational:   return "graduationcap"
        case .essay:         return "pencil.line"
        case .science:       return "atom"
        }
    }
}

// MARK: - 난이도

/// 콘텐츠 난이도
enum Difficulty: String, Codable, CaseIterable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"
    
    var displayName: String {
        switch self {
        case .easy:   return "쉬움"
        case .medium: return "보통"
        case .hard:   return "어려움"
        }
    }
    
    var starCount: Int {
        switch self {
        case .easy:   return 1
        case .medium: return 2
        case .hard:   return 3
        }
    }
}

// MARK: - JSON 로딩용 래퍼

/// JSON 파일에서 읽어올 때 사용하는 컨테이너
struct ReadingContentLibrary: Codable {
    let contents: [ReadingContent]
}
