import SwiftUI

struct MiakuQuestion {
    let text: String
    let options: [String]
}

private let questions: [MiakuQuestion] = [
    MiakuQuestion(text: "相手からLINEや連絡が来る頻度は？", options: ["ほぼ来ない", "たまに来る", "週に数回", "ほぼ毎日", "一日に何度も"]),
    MiakuQuestion(text: "二人きりの時、相手の態度は？", options: ["そっけない", "普通", "少し楽しそう", "明らかに嬉しそう", "特別感がある"]),
    MiakuQuestion(text: "目が合った時の相手の反応は？", options: ["すぐそらす", "無表情", "軽く微笑む", "また見てくる", "照れている"]),
    MiakuQuestion(text: "あなたの話を相手はどう聞く？", options: ["興味なさそう", "普通に聞く", "よく覚えている", "質問してくる", "すごく楽しそう"]),
    MiakuQuestion(text: "距離感やボディタッチは？", options: ["距離を置かれる", "普通の距離", "少し近い", "よく触れてくる", "かなり近い"]),
    MiakuQuestion(text: "あなたの予定や休日を聞いてくる？", options: ["全く聞かない", "たまに", "時々聞く", "よく聞く", "毎回聞いてくる"]),
    MiakuQuestion(text: "SNSでの反応は？", options: ["反応なし", "たまにいいね", "よくいいね", "コメントもする", "DMも来る"]),
    MiakuQuestion(text: "二人で会う提案への反応は？", options: ["断られる", "曖昧にされる", "都合が合えばOK", "喜んでOK", "相手から誘ってくる"])
]

struct MiakuCheckView: View {
    @ObservedObject var engine: AdviceEngine
    @ObservedObject var history: ConsultHistory
    @StateObject private var interstitial = InterstitialAdManager()
    @State private var currentQ = 0
    @State private var answers: [Int] = []
    @State private var result: MiakuResult?
    @State private var showResult = false
    @State private var showLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                MyakuariBackground()

                VStack(spacing: 0) {
                    if showLoading {
                        AnalyzingView()
                    } else if showResult, let result {
                        MiakuResultView(result: result) { reset() }
                    } else {
                        QuizView(
                            question: questions[currentQ],
                            index: currentQ,
                            total: questions.count,
                            onAnswer: answer
                        )
                    }

                    if !AppRuntime.isScreenshotRun {
                        BannerAdView(adUnitID: "ca-app-pub-9404799280370656/4483914374")
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("脈あり診断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                guard AppRuntime.isScreenshotRun && AppRuntime.screenshotScreen == "result" else { return }
                result = engine.analyzeMiaku(answers: [3, 4, 3, 4, 3, 3, 4, 4])
                showLoading = false
                showResult = true
            }
        }
    }

    private func answer(_ score: Int) {
        answers.append(score)
        if currentQ < questions.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentQ += 1
            }
        } else {
            result = engine.analyzeMiaku(answers: answers)
            history.saveDiagnosis(percentage: result!.percentage)
            withAnimation { showLoading = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if interstitial.isReady { interstitial.showAd() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        showLoading = false
                        showResult = true
                    }
                }
            }
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            currentQ = 0
            answers = []
            result = nil
            showResult = false
            showLoading = false
        }
    }
}

struct QuizView: View {
    let question: MiakuQuestion
    let index: Int
    let total: Int
    let onAnswer: (Int) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                GlassPanel(radius: 24) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            GradientIcon(systemName: "sparkles", size: 46)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI診断中")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.white)
                                Text("質問 \(index + 1) / \(total)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MyakuariTheme.softText)
                            }
                            Spacer()
                        }

                        ProgressView(value: Double(index + 1), total: Double(total))
                            .tint(MyakuariTheme.rose)
                            .scaleEffect(x: 1, y: 1.4, anchor: .center)

                        Text(question.text)
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                    }
                    .padding(20)
                }

                VStack(spacing: 12) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                        Button { onAnswer(idx) } label: {
                            HStack(spacing: 14) {
                                Text("\(idx + 1)")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color.white.opacity(0.12)))

                                Text(option)
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)

                                Spacer()

                                Image(systemName: "heart.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(MyakuariTheme.rose)
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.105)))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(MyakuariTheme.stroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }
}

struct AnalyzingView: View {
    @State private var rotate = false
    @State private var scale = false

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(MyakuariTheme.rose.opacity(0.18), lineWidth: 18)
                    .frame(width: 190, height: 190)
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(MyakuariTheme.romanceGradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                Image(systemName: "sparkles")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(.white)
                    .scaleEffect(scale ? 1.18 : 0.92)
                    .shadow(color: MyakuariTheme.rose, radius: 18)
            }

            VStack(spacing: 8) {
                Text("恋のサインを解析中")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                Text("視線、返信、距離感から脈あり度を計算しています")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MyakuariTheme.softText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 26)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) { rotate = true }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { scale = true }
        }
    }
}

struct MiakuResultView: View {
    let result: MiakuResult
    let onRetry: () -> Void
    @State private var animatedPercentage: Double = 0

    private var gaugeColor: Color {
        switch result.level {
        case .low:      return Color.white.opacity(0.55)
        case .medium:   return .orange
        case .high:     return MyakuariTheme.rose
        case .veryHigh: return MyakuariTheme.coral
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                GlassPanel(radius: 28) {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.11), lineWidth: 16)
                                .frame(width: 210, height: 210)
                            Circle()
                                .trim(from: 0, to: animatedPercentage / 100)
                                .stroke(MyakuariTheme.romanceGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 210, height: 210)
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 4) {
                                Text("脈あり度")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MyakuariTheme.softText)
                                Text("\(Int(animatedPercentage))%")
                                    .font(.system(size: 54, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(result.level.label)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(gaugeColor)
                            }
                        }

                        Text(result.psychology)
                            .font(.body.weight(.medium))
                            .foregroundStyle(MyakuariTheme.cream)
                            .lineSpacing(5)
                            .multilineTextAlignment(.center)
                    }
                    .padding(22)
                }

                ResultCard(title: "次にやるべきこと", icon: "arrow.up.heart.fill", tint: MyakuariTheme.lavender) {
                    VStack(spacing: 12) {
                        ForEach(Array(result.nextSteps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(idx + 1)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(MyakuariTheme.romanceGradient))
                                Text(step)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                ResultCard(title: "AIからのひとこと", icon: "brain.head.profile", tint: MyakuariTheme.rose) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(result.advice, id: \.self) { tip in
                            Text(tip)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MyakuariTheme.cream)
                                .lineSpacing(4)
                                .padding(13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                        }
                    }
                }

                Button { onRetry() } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("もう一度診断する")
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MyakuariTheme.romanceGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: MyakuariTheme.rose.opacity(0.35), radius: 18, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.15)) {
                animatedPercentage = Double(result.percentage)
            }
        }
    }
}

struct ResultCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder var content: Content

    init(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        GlassPanel(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.headline.weight(.black))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
                content
            }
            .padding(18)
        }
    }
}
