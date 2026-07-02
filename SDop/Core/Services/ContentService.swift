import Foundation

// MARK: - 콘텐츠 서비스

/// Resources/Books/ 디렉토리에서 로컬 JSON 파일을 읽어 읽기 콘텐츠를 관리하는 서비스
final class ContentService {
    
    static let shared = ContentService()
    
    /// 콘텐츠 캐시
    private var cachedContents: [ReadingContent]?
    
    private init() {}
    
    // MARK: - 공개 메서드
    
    /// 모든 읽기 콘텐츠를 로드한다
    func loadAllContents() -> [ReadingContent] {
        if let cached = cachedContents {
            return cached
        }
        
        let contents = loadContentsFromBundle()
        cachedContents = contents
        return contents
    }
    
    /// 카테고리별 콘텐츠를 필터링한다
    func contents(for category: ContentCategory) -> [ReadingContent] {
        loadAllContents().filter { $0.category == category }
    }
    
    /// 난이도별 콘텐츠를 필터링한다
    func contents(for difficulty: Difficulty) -> [ReadingContent] {
        loadAllContents().filter { $0.difficulty == difficulty }
    }
    
    /// ID로 특정 콘텐츠를 조회한다
    func content(for id: UUID) -> ReadingContent? {
        loadAllContents().first { $0.id == id }
    }
    
    /// 사용 가능한 모든 카테고리 목록 반환
    func availableCategories() -> [ContentCategory] {
        let categories = Set(loadAllContents().map { $0.category })
        return ContentCategory.allCases.filter { categories.contains($0) }
    }
    
    /// 추천 콘텐츠 - 아직 읽지 않은 것 중 하나 반환
    func recommendedContent(excluding readIds: Set<UUID> = []) -> ReadingContent? {
        let all = loadAllContents()
        let unread = all.filter { !readIds.contains($0.id) }
        // 읽지 않은 것이 있으면 그 중 랜덤, 없으면 전체에서 랜덤
        return unread.randomElement() ?? all.randomElement()
    }
    
    /// 캐시 초기화 (콘텐츠 갱신 시 호출)
    func invalidateCache() {
        cachedContents = nil
    }
    
    // MARK: - 내부 로딩
    
    /// 번들 내 Resources/Books/ 디렉토리의 모든 JSON 파일을 로드한다
    private func loadContentsFromBundle() -> [ReadingContent] {
        guard let bundleURL = Bundle.main.resourceURL else {
            print("[ContentService] 번들 리소스 경로를 찾을 수 없습니다")
            return []
        }
        
        // Resources/Books/ 경로 탐색
        let booksURL = bundleURL.appendingPathComponent("Resources/Books", isDirectory: true)
        
        var contents: [ReadingContent] = []
        
        // 번들 내 .json 파일 검색 (Books 폴더 또는 번들 루트)
        let jsonFiles = findJSONFiles(in: booksURL)
            ?? findJSONFiles(in: bundleURL)
            ?? []
        
        for fileURL in jsonFiles {
            if let content = loadContent(from: fileURL) {
                contents.append(content)
            }
        }
        
        // JSON 파일이 없으면 샘플 콘텐츠 제공
        if contents.isEmpty {
            print("[ContentService] JSON 파일을 찾을 수 없어 샘플 콘텐츠를 제공합니다")
            contents = sampleContents()
        }
        
        return contents.sorted { $0.title < $1.title }
    }
    
    /// 특정 경로의 JSON 파일을 읽어 ReadingContent로 디코딩한다
    private func loadContent(from url: URL) -> ReadingContent? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(ReadingContent.self, from: data)
        } catch {
            print("[ContentService] JSON 디코딩 실패: \(url.lastPathComponent) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 디렉토리 내 .json 파일 검색
    private func findJSONFiles(in directory: URL) -> [URL]? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else { return nil }
        
        do {
            let files = try fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            return jsonFiles.isEmpty ? nil : jsonFiles
        } catch {
            print("[ContentService] 디렉토리 읽기 실패: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 샘플 콘텐츠 (JSON 파일이 없을 때 사용)

extension ContentService {
    
    /// 개발/테스트용 샘플 콘텐츠 생성
    func sampleContents() -> [ReadingContent] {
        [
            ReadingContent(
                id: UUID(),
                title: "춘향전 - 제1장",
                author: "작자 미상",
                category: .koreanClassic,
                pages: [
                    Page(pageNumber: 1, content: "남원 부사 이도령의 아들 이몽룡은 학문이 뛰어나고 풍채가 빼어난 인물이었다. 어느 봄날, 그는 광한루에 올라 주변 풍경을 감상하고 있었다. 연못에는 연꽃이 피어나고 버드나무 가지는 봄바람에 살랑이고 있었다."),
                    Page(pageNumber: 2, content: "그때 연못가에서 그네를 뛰는 아름다운 여인을 발견하였다. 그녀는 춘향이었으니, 기생 월매의 딸로 그 미모가 남원 땅에 소문이 자자하였다. 이몽룡은 한눈에 반하여 시를 한 수 읊었다."),
                    Page(pageNumber: 3, content: "춘향 또한 이몽룡의 풍모에 마음이 끌려 두 사람은 그날부터 사랑을 속삭이기 시작하였다. 이몽룡은 춘향의 집을 드나들며 밤마다 시를 주고받았고, 두 사람의 사랑은 깊어만 갔다."),
                    Page(pageNumber: 4, content: "그러나 행복한 나날은 오래가지 못하였다. 이몽룡의 아버지가 한양으로 전임하게 되어 이몽룡도 떠나야 할 처지가 되었다. 두 사람은 광한루에서 작별의 맹세를 하였다."),
                    Page(pageNumber: 5, content: "\"내가 반드시 돌아와 그대를 데리리라.\" 이몽룡은 춘향에게 약속하고 한양으로 떠났다. 춘향은 눈물을 흘리며 그를 배웅하였으나, 그 뒤로 남원에는 새 부사가 부임하게 되었다.")
                ],
                quiz: [
                    QuizQuestion(id: UUID(), question: "이몽룡이 춘향을 처음 만난 곳은?", options: ["남원 읍내", "광한루", "한양", "춘향의 집"], correctIndex: 1, explanation: "이몽룡은 광한루에 올랐을 때 춘향을 처음 보았습니다."),
                    QuizQuestion(id: UUID(), question: "춘향의 어머니 월매의 직업은?", options: ["양반", "기생", "상인", "무당"], correctIndex: 1, explanation: "춘향은 기생 월매의 딸입니다."),
                    QuizQuestion(id: UUID(), question: "이몽룡이 남원을 떠난 이유는?", options: ["과거 시험", "아버지의 전임", "병환", "여행"], correctIndex: 1, explanation: "이몽룡의 아버지가 한양으로 전임하게 되어 떠나게 되었습니다.")
                ],
                difficulty: .easy,
                coverImageName: nil
            ),
            ReadingContent(
                id: UUID(),
                title: "흥부전 - 놀부의 욕심",
                author: "작자 미상",
                category: .koreanClassic,
                pages: [
                    Page(pageNumber: 1, content: "옛날에 흥부와 놀부라는 형제가 살고 있었다. 흥부는 마음씨가 착하고 성격이 온화하였으나, 놀부는 욕심이 많고 마음이 비뚤어진 사람이었다. 부모님이 돌아가시자 놀부는 재산을 모두 차지하고 흥부를 내쫓았다."),
                    Page(pageNumber: 2, content: "흥부는 가난하지만 착한 마음씨로 이웃들과 사이좋게 지냈다. 어느 봄날, 제비 한 쌍이 흥부네 처마 밑에 둥지를 틀었다. 그런데 뱀이 새끼 제비의 다리를 물어뜯는 것을 보고 흥부는 뱀을 쫓아내고 제비 다리를 치료해 주었다."),
                    Page(pageNumber: 3, content: "가을이 되어 제비가 남쪽 나라로 떠났다. 그런데 다음 해 봄, 그 제비가 돌아와서 박씨 하나를 흥부에게 물어다 주었다. 흥부는 그 박씨를 정성껏 심었다."),
                    Page(pageNumber: 4, content: "박이 자라서 열리니 그 크기가 집채만 하였다. 흥부가 박을 타니 그 안에서 금은보화가 쏟아져 나왔다. 흥부는 부자가 되어 이웃들과 나누며 행복하게 살았다."),
                    Page(pageNumber: 5, content: "이 소식을 들은 놀부는 욕심이 나서 일부러 제비 다리를 부러뜨리고 치료해 주었다. 다음 해 박씨를 받은 놀부도 박을 타니, 그 안에서 도깨비가 나와 놀부의 재산을 모두 빼앗아 갔다.")
                ],
                quiz: [
                    QuizQuestion(id: UUID(), question: "흥부가 제비에게 무엇을 해주었나요?", options: ["먹이를 주었다", "다리를 치료해 주었다", "새 둥지를 만들어 주었다", "남쪽 나라로 데려다 주었다"], correctIndex: 1, explanation: "뱀에게 물린 제비 다리를 치료해 주었습니다."),
                    QuizQuestion(id: UUID(), question: "박 속에서 나온 것은?", options: ["도깨비", "금은보화", "음식", "옷감"], correctIndex: 1, explanation: "흥부의 박에서는 금은보화가 나왔습니다."),
                    QuizQuestion(id: UUID(), question: "놀부의 박에서는 무엇이 나왔나요?", options: ["금은보화", "도깨비", "제비", "아무것도 없었다"], correctIndex: 1, explanation: "놀부의 박에서는 도깨비가 나와 재산을 빼앗아 갔습니다.")
                ],
                difficulty: .easy,
                coverImageName: nil
            ),
            ReadingContent(
                id: UUID(),
                title: "홍길동전 - 활빈당의 탄생",
                author: "허균",
                category: .koreanClassic,
                pages: [
                    Page(pageNumber: 1, content: "조선 시대, 서자로 태어난 홍길동은 뛰어난 재능을 가지고 있었으나 신분의 한계로 인해 마음껏 살 수가 없었다. 그의 아버지 홍판서는 높은 벼슬을 지닌 양반이었지만, 길동을 제대로 대접해 주지 못하였다."),
                    Page(pageNumber: 2, content: "길동은 어려서부터 글재주와 무예가 뛰어났다. 그러나 서자라는 이유로 관직에 나아갈 수 없었고, 형제들 사이에서도 차별을 받아야 했다. 이러한 불합리함이 길동의 마음속에 분노를 키워갔다."),
                    Page(pageNumber: 3, content: "결국 길동은 집을 나와 산으로 들어갔다. 그곳에서 뜻을 같이하는 동무들을 모아 '활빈당'을 결성하였다. 활빈당은 부자들의 재산을 빼앗아 가난한 백성들에게 나누어 주었다."),
                    Page(pageNumber: 4, content: "조정에서는 홍길동을 도적으로 규정하고 토벌군을 보냈다. 그러나 길동은 신출귀몰하는 재주로 번번이 위기를 벗어났다. 백성들은 길동을 의적으로 칭송하였다."),
                    Page(pageNumber: 5, content: "길동은 이상적인 나라를 꿈꾸며 '율도국'이라는 나라를 세웠다. 그곳에서는 서자와 양반의 구분이 없었고, 모든 사람이 평등하게 대접받았다. 이것이 바로 허균이 꿈꾸었던 이상 사회의 모습이었다.")
                ],
                quiz: [
                    QuizQuestion(id: UUID(), question: "홍길동이 차별받은 이유는?", options: ["가난해서", "서자(첩의 자식)이어서", "무예가 부족해서", "글을 몰라서"], correctIndex: 1, explanation: "홍길동은 서자라는 신분적 한계로 차별을 받았습니다."),
                    QuizQuestion(id: UUID(), question: "홍길동이 결성한 조직의 이름은?", options: ["의적단", "활빈당", "농민군", "청년단"], correctIndex: 1, explanation: "홍길동은 '활빈당'을 결성하여 백성을 도왔습니다."),
                    QuizQuestion(id: UUID(), question: "홍길동이 세운 이상 나라의 이름은?", options: ["태평성대", "대동세계", "율도국", "이상향"], correctIndex: 2, explanation: "홍길동은 신분 차별이 없는 '율도국'을 세웠습니다.")
                ],
                difficulty: .medium,
                coverImageName: nil
            )
        ]
    }
}
