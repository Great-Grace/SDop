import SwiftUI

struct QuizView: View {
    let questions: [QuizQuestion]
    let onComplete: (Double, Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestion: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var correctAnswers: Int = 0
    @State private var showExplanation: Bool = false
    @State private var isFinished: Bool = false
    
    private var progress: Double {
        Double(currentQuestion + 1) / Double(questions.count)
    }
    private var score: Double {
        Double(correctAnswers) / Double(questions.count)
    }
    private var passed: Bool { score >= 0.6 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isFinished {
                    resultView
                } else {
                    questionView
                }
            }
            .navigationTitle("퀴즈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !isFinished {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("닫기") { dismiss() }
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // MARK: - Question View
    private var questionView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                ProgressView(value: progress).tint(Color("AccentOrange"))
                Text("\(currentQuestion + 1) / \(questions.count)")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20).padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    Text(questions[currentQuestion].question)
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                            optionButton(index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if showExplanation {
                        explanationCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            
            if showExplanation {
                Button { nextQuestion() } label: {
                    Text(currentQuestion < questions.count - 1 ? "다음 문제" : "결과 보기")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color("AccentOrange"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Option Button
    private func optionButton(index: Int) -> some View {
        let question = questions[currentQuestion]
        let isSelected = selectedAnswer == index
        let isCorrect = question.isCorrect(index)
        let showResult = showExplanation
        
        return Button {
            guard selectedAnswer == nil else { return }
            selectedAnswer = index
            if isCorrect { correctAnswers += 1 }
            withAnimation(.spring(response: 0.3)) { showExplanation = true }
        } label: {
            HStack {
                Text(question.options[index])
                    .font(.body)
                    .foregroundStyle(optionTextColor(isSelected: isSelected, isCorrect: isCorrect, showResult: showResult))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if showResult {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle"))
                        .foregroundStyle(isCorrect ? .green : (isSelected ? .red : .white.opacity(0.2)))
                }
            }
            .padding(16)
            .background(optionBgColor(isSelected: isSelected, isCorrect: isCorrect, showResult: showResult))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(optionBorderColor(isSelected: isSelected, isCorrect: isCorrect, showResult: showResult), lineWidth: 1)
            )
        }
        .disabled(showExplanation)
    }
    
    private func optionTextColor(isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult && isCorrect { return .green }
        if showResult && isSelected { return .red }
        return .white
    }
    
    private func optionBgColor(isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult && isCorrect { return .green.opacity(0.1) }
        if showResult && isSelected { return .red.opacity(0.1) }
        if isSelected { return Color("AccentOrange").opacity(0.2) }
        return .white.opacity(0.05)
    }
    
    private func optionBorderColor(isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult && isCorrect { return .green.opacity(0.5) }
        if showResult && isSelected { return .red.opacity(0.5) }
        if isSelected { return Color("AccentOrange") }
        return .white.opacity(0.1)
    }
    
    // MARK: - Explanation
    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundStyle(Color("AccentOrange"))
                Text("해설").font(.subheadline).fontWeight(.semibold).foregroundStyle(Color("AccentOrange"))
            }
            Text(questions[currentQuestion].explanation)
                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AccentOrange").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Result View
    private var resultView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(passed ? .green : .red)
                .symbolEffect(.bounce, value: isFinished)
            
            VStack(spacing: 8) {
                Text(passed ? "축하합니다!" : "아쉽네요!")
                    .font(.title).fontWeight(.bold).foregroundStyle(.white)
                Text(passed ? "퀴즈를 통과했습니다!" : "60% 이상 맞춰야 합니다")
                    .font(.body).foregroundStyle(.white.opacity(0.6))
            }
            
            HStack(spacing: 24) {
                resultStat(value: "\(correctAnswers)", label: "정답", color: .green)
                resultStat(value: "\(questions.count - correctAnswers)", label: "오답", color: .red)
                resultStat(value: "\(Int(score * 100))%", label: "점수", color: Color("AccentOrange"))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(passed ? Color.green : Color.red)
                        .frame(width: geo.size.width * score)
                }
            }
            .frame(height: 8).padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 12) {
                if passed {
                    Button {
                        onComplete(score, true)
                        dismiss()
                    } label: {
                        Text("앱 해제하기")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button { resetQuiz() } label: {
                        Text("다시 도전하기")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color("AccentOrange"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button { dismiss() } label: {
                        Text("나중에 하기")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 32).padding(.bottom, 48)
        }
    }
    
    private func resultStat(value: String, label: String, color: Color) -> some View {
        VStack {
            Text(value).font(.title).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
        }
    }
    
    // MARK: - Actions
    private func nextQuestion() {
        if currentQuestion < questions.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                currentQuestion += 1
                selectedAnswer = nil
                showExplanation = false
            }
        } else {
            withAnimation(.spring(response: 0.4)) { isFinished = true }
        }
    }
    
    private func resetQuiz() {
        withAnimation {
            currentQuestion = 0
            selectedAnswer = nil
            correctAnswers = 0
            showExplanation = false
            isFinished = false
        }
    }
}
