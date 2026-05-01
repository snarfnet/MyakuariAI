import SwiftUI

private let kBannerID = "ca-app-pub-9404799280370656/4483914374"

struct ContentView: View {
    @StateObject private var engine = AdviceEngine()
    @StateObject private var history = ConsultHistory()

    var body: some View {
        TabView {
            HomeView(engine: engine, history: history)
                .tabItem { Label("ホーム", systemImage: "heart.text.clipboard") }

            MiakuCheckView(engine: engine, history: history)
                .tabItem { Label("脈あり診断", systemImage: "waveform.path.ecg") }

            HistoryView(history: history)
                .tabItem { Label("履歴", systemImage: "clock.arrow.circlepath") }
        }
        .tint(.pink)
    }
}

// MARK: - Home

struct HomeView: View {
    @ObservedObject var engine: AdviceEngine
    @ObservedObject var history: ConsultHistory
    @State private var selectedMode: ConsultMode?
    @State private var dailyQuote = ""

    private let quotes = [
        "その恋、AIが一緒に考える",
        "あなたの気持ち、大切にして",
        "焦らなくて大丈��",
        "小さな勇気が恋を動かす",
        "今日も素敵な一日になる",
        "あなたらしさが一番の魅力",
        "恋は考えすぎないのがコツ",
        "直感を信じてみて",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Daily quote
                        VStack(spacing: 8) {
                            Image(systemName: "cloud.fill")
                                .font(.title2)
                                .foregroundStyle(.pink.opacity(0.5))
                            Text("今日の一言")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(dailyQuote)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.pink.opacity(0.08), .purple.opacity(0.06)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .padding(.horizontal)

                        // Category selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("どんな相談？")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 12) {
                                ForEach(ConsultMode.allCases, id: \.self) { mode in
                                    ModeCard(mode: mode) {
                                        selectedMode = mode
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Recent history
                        if !history.sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("最近の相談")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(history.sessions.prefix(3)) { session in
                                    HStack {
                                        Image(systemName: session.mode.icon)
                                            .foregroundStyle(.pink)
                                        VStack(alignment: .leading) {
                                            Text(session.mode.rawValue)
                                                .font(.subheadline)
                                            Text(session.preview)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(session.dateLabel)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }

                BannerAdView(adUnitID: kBannerID).frame(height: 50)
            }
            .navigationTitle("脈ありAI")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMode) { mode in
                ChatView(mode: mode, engine: engine, history: history)
            }
            .onAppear {
                let idx = Calendar.current.component(.hour, from: Date()) % quotes.count
                dailyQuote = quotes[idx]
            }
        }
    }
}

extension ConsultMode: Identifiable {
    var id: String { rawValue }
}

struct ModeCard: View {
    let mode: ConsultMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(.pink)
                Text(mode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.pink.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chat View

struct ChatView: View {
    let mode: ConsultMode
    @ObservedObject var engine: AdviceEngine
    @ObservedObject var history: ConsultHistory
    @Environment(\.dismiss) private var dismiss
    @StateObject private var interstitial = InterstitialAdManager()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @AppStorage("chat_session_count") private var sessionCount = 0

    private let templates: [String] = [
        "既読スルーされた",
        "返信が遅い",
        "目が合う気がする",
        "2人きりになりたがる",
        "連絡先を聞かれた",
        "デートに誘われた",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isThinking {
                                HStack {
                                    ThinkingDots()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Templates
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(templates, id: \.self) { t in
                            Button {
                                sendMessage(t)
                            } label: {
                                Text(t)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.1))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }

                // Input bar
                HStack(spacing: 8) {
                    TextField("相談を入力…", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit { sendMessage(inputText) }

                    Button {
                        sendMessage(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.pink)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                BannerAdView(adUnitID: kBannerID).frame(height: 50)
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        sessionCount += 1
                        if sessionCount % 3 == 0 && interstitial.isReady {
                            interstitial.showAd()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                let greeting = greetingForMode(mode)
                messages.append(ChatMessage(text: greeting, isUser: false))
            }
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(text: trimmed, isUser: true))
        inputText = ""
        isThinking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...1.5)) {
            let response = generateResponse(for: trimmed, mode: mode)
            messages.append(ChatMessage(text: response, isUser: false))
            isThinking = false

            // Save to history
            history.save(mode: mode, messages: messages)
        }
    }

    private func generateResponse(for input: String, mode: ConsultMode) -> String {
        let advices = engine.getAdvice(for: mode, count: 2)
        let lower = input.lowercased()

        // Tone prefix based on mode
        let prefix: String
        switch mode.tone {
        case "gentle":
            prefix = ["うんうん、わかるよ。", "その気持ち、大事にしてね。", "焦らなくて大丈夫。"].randomElement()!
        case "analytical":
            prefix = ["なるほど、分析してみると…", "興味深いポイントだね。", "客観的に見ると…"].randomElement()!
        case "comforting":
            prefix = ["辛かったね。", "あなたは悪くないよ。", "時間が味方してくれる。"].randomElement()!
        case "direct":
            prefix = ["はっきり言うね。", "率直に言うと…", "ここは冷静に。"].randomElement()!
        case "practical":
            prefix = ["具体的にアドバイスすると…", "実践的に考えると…", "ポイントはここ。"].randomElement()!
        default:
            prefix = ["そうだね。", "なるほどね。", "一緒に考えよう。"].randomElement()!
        }

        // Contextual analysis
        var analysis = ""
        if lower.contains("既読") || lower.contains("スルー") || lower.contains("返信") || lower.contains("遅い") {
            analysis = "返信のペースだけで判断するのは早いかも。忙しいだけの可能性もあるし、返信の内容や質が大事なポイントだよ��"
        } else if lower.contains("目") || lower.contains("合う") || lower.contains("見") {
            analysis = "目が合うのは大きなサイン。特に、目が合った後に相手が微笑んだり目をそらしたりするなら、意識してる可能性が高いよ。"
        } else if lower.contains("2人") || lower.contains("ふたり") || lower.contains("二人") {
            analysis = "2人きりの時間を作ろうとするのは好意のサイン。相手から誘ってくるなら、かなりの脈ありポイントだよ。"
        } else if lower.contains("連絡先") || lower.contains("LINE") || lower.contains("電話") {
            analysis = "連絡先を聞くのは一歩踏み込みたいという気持ちの表れ。相手から聞かれたなら、それはかなりポジティブなサイン。"
        } else if lower.contains("デ��ト") || lower.contains("誘") || lower.contains("遊び") {
            analysis = "デートに誘うのは明確な好意の表現。特に2人きりで会いたがるなら、脈あり度はかなり高い。"
        } else if lower.contains("辛い") || lower.contains("別れ") || lower.contains("失恋") || lower.contains("泣") {
            analysis = "今は辛い時期だね。でも、この痛みはいつか必ず和らぐ。自分を責めないで、今は自分を大切にする時間だよ。"
        } else if !advices.isEmpty {
            analysis = advices[0]
        } else {
            analysis = "あなたの状況、もう少し詳しく教えてくれる？具体的なエピソードがあると、より的確なアドバイスができるよ。"
        }

        var response = prefix + "\n\n" + analysis

        // Add book-based tip
        if advices.count > 1 {
            let tip = advices.last!
            if tip.count < 300 {
                response += "\n\n💡 " + tip
            }
        }

        return response
    }

    private func greetingForMode(_ mode: ConsultMode) -> String {
        switch mode {
        case .kataomoi:
            return "片思いの相談だね。\n\n気になる相手のこと、何でも話してみて。一緒に考えよう。\n\n下のテンプレートをタップするか、自由に入力してね。"
        case .koibito:
            return "恋人との関係について相談したいんだね。\n\n2人の間で気になること、話してみて。"
        case .myakuari:
            return "相手の気持ちが気になるんだね。\n\n相手の行動や反応を教えてくれたら、脈あり度を分析するよ。"
        case .line:
            return "LINEのやりとりで悩んでるんだね。\n\nスクショの内容を文字で教えてくれたら、一緒に読み解くよ。"
        case .shitsuren:
            return "辛い時に相談してくれてありがとう。\n\n無理しなくていいよ。少しずつ話し���みて。"
        case .shuraba:
            return "大変な状況なんだね。\n\n落ち着いて、何があったか教えて。一緒に整理しよう。"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let date = Date()
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                Image(systemName: "heart.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.pink)
            }

            Text(message.text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                        ? Color.pink.opacity(0.15)
                        : Color(.secondarySystemBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}

struct ThinkingDots: View {
    @State private var dot = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.pink.opacity(dot == i ? 1 : 0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dot = (dot + 1) % 3
            }
        }
    }
}
