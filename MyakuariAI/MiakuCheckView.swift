import SwiftUI

struct MiakuQuestion {
    let text: String
    let options: [String]
}

private let questions: [MiakuQuestion] = [
    MiakuQuestion(text: "相手からLINEや連絡が来る頻度は？", options: [
        "ほぼ来ない", "たまに来る", "週に数回", "ほぼ毎日", "1日に何度も"
    ]),
    MiakuQuestion(text: "2人きりの時、相手の態度は？", options: [
        "素っ気ない", "普通", "少し楽しそう", "明らかに嬉しそう", "特別感がある"
    ]),
    MiakuQuestion(text: "目が合った時の相手の反応は？", options: [
        "すぐそらす", "無表情", "軽く微笑む", "じっと見つめる", "照れる"
    ]),
    MiakuQuestion(text: "あなたの話を相手はどう聞く？", options: [
        "興味なさそう", "普通に聞く", "よく覚えてる", "質問してくる", "すごく楽しそう"
    ]),
    MiakuQuestion(text: "ボディタッチや距離感は？", options: [
        "距離を置かれる", "普通の距離", "少し近い", "よく触れてくる", "かなり近い"
    ]),
    MiakuQuestion(text: "あなたの予定や休日を聞いてくる？", options: [
        "全く聞かない", "たまに", "時々聞く", "よく聞く", "毎回聞いてくる"
    ]),
    MiakuQuestion(text: "相手のSNSでの反応は？", options: [
        "反応なし", "たまにいいね", "よくいいね", "コメントもする", "DMも来る"
    ]),
    MiakuQuestion(text: "2人で会う提案をした時の反応は？", options: [
        "断られる", "曖昧にされる", "都合が合えばOK", "喜んでOK", "相手から誘ってくる"
    ]),
]

struct MiakuCheckView: View {
    @ObservedObject var engine: AdviceEngine
    @ObservedObject var history: ConsultHistory
    @State private var currentQ = 0
    @State private var answers: [Int] = []
    @State private var result: MiakuResult?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showResult, let result = result {
                    MiakuResultView(result: result) {
                        reset()
                    }
                } else {
                    QuizView(
                        question: questions[currentQ],
                        index: currentQ,
                        total: questions.count,
                        onAnswer: { score in
                            answers.append(score)
                            if currentQ < questions.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentQ += 1
                                }
                            } else {
                                result = engine.analyzeMiaku(answers: answers)
                                withAnimation(.spring(response: 0.5)) {
                                    showResult = true
                                }
                                history.saveDiagnosis(percentage: result!.percentage)
                            }
                        }
                    )
                }

                BannerAdView(adUnitID: "ca-app-pub-9404799280370656/1118636003")
                    .frame(height: 50)
            }
            .navigationTitle("脈あり診断")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func reset() {
        withAnimation {
            currentQ = 0
            answers = []
            result = nil
            showResult = false
        }
    }
}

// MARK: - Quiz

struct QuizView: View {
    let question: MiakuQuestion
    let index: Int
    let total: Int
    let onAnswer: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: Double(index), total: Double(total))
                    .tint(.pink)
                Text("\(index + 1) / \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)

            Spacer()

            // Question
            Text(question.text)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            // Options
            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    Button {
                        onAnswer(idx)
                    } label: {
                        HStack {
                            Text(option)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "\(idx + 1).circle")
                                .foregroundStyle(.pink.opacity(0.5))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pink.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Result (THE KEY SCREEN)

struct MiakuResultView: View {
    let result: MiakuResult
    let onRetry: () -> Void
    @State private var animatedPercentage: Double = 0
    @State private var showDetails = false

    private var gaugeColor: Color {
        switch result.level {
        case .low:      return .gray
        case .medium:   return .orange
        case .high:     return .pink
        case .veryHigh: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Gauge
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 14)
                            .frame(width: 180, height: 180)

                        Circle()
                            .trim(from: 0, to: animatedPercentage / 100)
                            .stroke(
                                gaugeColor,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("脈あり度")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(animatedPercentage))%")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(gaugeColor)
                        }
                    }

                    Text(result.level.label)
                        .font(.headline)
                        .foregroundStyle(gaugeColor)
                }
                .padding(.top, 20)

                // Psychology card
                VStack(alignment: .leading, spacing: 12) {
                    Label("相手の心理", systemImage: "brain.head.profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)

                    Text(result.psychology)
                        .font(.subheadline)
                        .lineSpacing(4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.pink.opacity(0.06))
                )
                .padding(.horizontal)

                // Next steps card
                VStack(alignment: .leading, spacing: 12) {
                    Label("次にやるべきこと", systemImage: "arrow.right.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)

                    ForEach(Array(result.nextSteps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(idx + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.purple.opacity(0.7)))

                            Text(step)
                                .font(.subheadline)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.purple.opacity(0.06))
                )
                .padding(.horizontal)

                // Book-based advice
                if !result.advice.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("恋愛の知恵", systemImage: "book.closed")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)

                        ForEach(result.advice, id: \.self) { tip in
                            Text(tip)
                                .font(.caption)
                                .lineSpacing(3)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange.opacity(0.06))
                                )
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }

                // Retry button
                Button {
                    onRetry()
                } label: {
                    Text("もう一度診断する")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.pink))
                }
                .padding(.vertical, 8)

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedPercentage = Double(result.percentage)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { showDetails = true }
            }
        }
    }
}
