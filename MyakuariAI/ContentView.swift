import SwiftUI

private let kBannerID = "ca-app-pub-9404799280370656/4483914374"

private enum MainTab: Hashable {
    case home, diagnosis, history
}

struct ContentView: View {
    @StateObject private var engine = AdviceEngine()
    @StateObject private var history = ConsultHistory()
    @State private var selectedTab: MainTab = AppRuntime.screenshotScreen == "result" ? .diagnosis : .home

    var body: some View {
        if AppRuntime.isScreenshotRun && AppRuntime.screenshotScreen == "chat" {
            ChatView(mode: .myakuari, engine: engine, history: history)
        } else {
            TabView(selection: $selectedTab) {
            HomeView(engine: engine, history: history)
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(MainTab.home)

            MiakuCheckView(engine: engine, history: history)
                .tabItem { Label("診断", systemImage: "sparkles") }
                .tag(MainTab.diagnosis)

            HistoryView(history: history)
                .tabItem { Label("履歴", systemImage: "clock.fill") }
                .tag(MainTab.history)
        }
            .tint(MyakuariTheme.rose)
        }
    }
}

struct HomeView: View {
    @ObservedObject var engine: AdviceEngine
    @ObservedObject var history: ConsultHistory
    @State private var selectedMode: ConsultMode?
    @State private var pulse = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                MyakuariBackground()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            hero
                            quickActions
                            modeGrid
                            recentHistory
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 28)
                    }

                    if !AppRuntime.isScreenshotRun { BannerAdView(adUnitID: kBannerID).frame(height: 50) }
                }
            }
            .navigationTitle("脈ありAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedMode) { mode in
                ChatView(mode: mode, engine: engine, history: history)
            }
        }
    }

    private var hero: some View {
        GlassPanel(radius: 28) {
            ZStack(alignment: .bottomLeading) {
                Image("RomanceGuide")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 360)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, MyakuariTheme.ink.opacity(0.45), MyakuariTheme.ink.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("AI恋愛相談")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.16)))

                    Text("そのサイン、\n恋の可能性まで読む。")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(2)

                    Text("LINE、視線、距離感、誘い方。曖昧な行動をAI風に整理して、次の一手まで提案します。")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MyakuariTheme.softText)
                        .lineSpacing(4)

                    Button {
                        selectedMode = .myakuari
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                            Text("脈あり診断をはじめる")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 15)
                        .background(MyakuariTheme.romanceGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: MyakuariTheme.rose.opacity(0.45), radius: pulse ? 22 : 10, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(pulse ? 1.015 : 1)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
                }
                .padding(22)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            MetricPill(title: "相談モード", value: "6", icon: "slider.horizontal.3")
            MetricPill(title: "診断質問", value: "8", icon: "checklist")
            MetricPill(title: "保存履歴", value: "\(history.sessions.count)", icon: "clock")
        }
    }

    private var modeGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "どんな恋を相談する？", subtitle: "悩みに近いカードを選んでください")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ConsultMode.allCases, id: \.self) { mode in
                    ModeCard(mode: mode) { selectedMode = mode }
                }
            }
        }
    }

    @ViewBuilder
    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "最近の相談", subtitle: history.sessions.isEmpty ? "相談するとここに残ります" : "前回の続きから見直せます")

            if history.sessions.isEmpty {
                GlassPanel(radius: 20) {
                    HStack(spacing: 12) {
                        GradientIcon(systemName: "heart.text.square.fill", size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("まだ履歴はありません")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("気になる相手の行動を入力して、最初の相談を始めましょう。")
                                .font(.caption)
                                .foregroundStyle(MyakuariTheme.softText)
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(history.sessions.prefix(3)) { session in
                        HistoryRow(session: session)
                    }
                }
            }
        }
    }
}

extension ConsultMode: Identifiable {
    var id: String { rawValue }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(MyakuariTheme.softText)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        GlassPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(MyakuariTheme.rose)
                Text(value)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MyakuariTheme.softText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
        }
    }
}

struct ModeCard: View {
    let mode: ConsultMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassPanel(radius: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        GradientIcon(systemName: mode.icon, size: 46)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(mode.rawValue)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text(mode.subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(MyakuariTheme.softText)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                .padding(15)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HistoryRow: View {
    let session: ConsultSession

    var body: some View {
        GlassPanel(radius: 18) {
            HStack(spacing: 12) {
                GradientIcon(systemName: session.mode.icon, size: 42)
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.mode.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(session.preview)
                        .font(.caption)
                        .foregroundStyle(MyakuariTheme.softText)
                        .lineLimit(1)
                }
                Spacer()
                Text(session.dateLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.48))
            }
            .padding(14)
        }
    }
}

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

    private let templates = ["既読スルー", "返信が遅い", "目が合う", "二人きり", "連絡先", "デート"]

    var body: some View {
        NavigationStack {
            ZStack {
                MyakuariBackground()

                VStack(spacing: 0) {
                    chatHeader

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 13) {
                                ForEach(messages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.id)
                                }
                                if isThinking {
                                    ThinkingBubble()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    templateBar
                    inputBar
                    if !AppRuntime.isScreenshotRun { BannerAdView(adUnitID: kBannerID).frame(height: 50) }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if messages.isEmpty {
                    if AppRuntime.isScreenshotRun && AppRuntime.screenshotScreen == "chat" {
                        messages = screenshotMessages()
                    } else {
                        messages.append(ChatMessage(text: greetingForMode(mode), isUser: false))
                    }
                }
            }
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button {
                sessionCount += 1
                if sessionCount % 3 == 0 && interstitial.isReady {
                    interstitial.showAd()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)

            Image("RomanceGuide")
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(MyakuariTheme.rose.opacity(0.7), lineWidth: 2))

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.rawValue)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text("脈ありAIが相談中")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MyakuariTheme.softText)
            }
            Spacer()
            GradientIcon(systemName: mode.icon, size: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var templateBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templates, id: \.self) { text in
                    Button { sendMessage(text) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.caption2.weight(.black))
                            Text(text)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .overlay(Capsule().stroke(MyakuariTheme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("相談を入力…", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(MyakuariTheme.stroke, lineWidth: 1))
                .submitLabel(.send)
                .onSubmit { sendMessage(inputText) }

            Button { sendMessage(inputText) } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(MyakuariTheme.romanceGradient)
                    .clipShape(Circle())
                    .shadow(color: MyakuariTheme.rose.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(text: trimmed, isUser: true))
        inputText = ""
        isThinking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...1.4)) {
            let response = generateResponse(for: trimmed, mode: mode)
            messages.append(ChatMessage(text: response, isUser: false))
            isThinking = false
            history.save(mode: mode, messages: messages)
        }
    }

    private func generateResponse(for input: String, mode: ConsultMode) -> String {
        let lower = input.lowercased()
        let prefix: String
        switch mode.tone {
        case "gentle": prefix = ["うんうん、ちゃんと見てみるね。", "その気持ち、すごく自然だよ。", "焦らず一緒に整理しよう。"].randomElement()!
        case "analytical": prefix = ["サインを分解すると…", "脈あり度を読むならここが大事。", "客観的に見ると…"].randomElement()!
        case "comforting": prefix = ["つらかったね。", "まずは深呼吸しよう。", "今は無理に強がらなくていいよ。"].randomElement()!
        case "direct": prefix = ["はっきり言うね。", "ここは冷静に見よう。", "今やるべきことを絞るね。"].randomElement()!
        case "practical": prefix = ["次の返信はこう考えて。", "LINEなら温度感が大事。", "実践的にいくね。"].randomElement()!
        default: prefix = ["なるほど、いい相談だね。", "一緒に見ていこう。", "状況を整理するね。"].randomElement()!
        }

        let analysis: String
        if lower.contains("既読") || lower.contains("スルー") || lower.contains("返信") || lower.contains("遅") {
            analysis = "返信の早さだけで脈なし判定はまだ早いよ。大事なのは、返ってきた内容に質問や感情があるか。短くても会話を続ける気配があるなら、まだ可能性は残ってる。"
        } else if lower.contains("目") || lower.contains("視線") || lower.contains("合う") {
            analysis = "目が合う回数が増えているなら、かなり良いサイン。特に目が合ったあとに笑う、照れる、また見てくるなら、意識している可能性が高いよ。"
        } else if lower.contains("二人") || lower.contains("2人") || lower.contains("ふたり") {
            analysis = "二人きりの時間を嫌がらないのは大きいよ。相手から理由を作って近づいてくるなら、脈あり度はかなり上がる。"
        } else if lower.contains("line") || lower.contains("連絡") || lower.contains("電話") {
            analysis = "連絡先やLINEは、関係を続けたい人にしか聞きにくいもの。相手発信ならポジティブ。次は軽い話題でテンポを作ってみて。"
        } else if lower.contains("デート") || lower.contains("誘") || lower.contains("会") {
            analysis = "具体的に会う話が出ているならかなり強いサイン。日時や場所まで進むなら、相手も現実的に距離を縮めたいと思っていそう。"
        } else if lower.contains("失恋") || lower.contains("別れ") || lower.contains("辛") || lower.contains("泣") {
            analysis = "今は結論を急がなくて大丈夫。まずは相手の気持ちより、自分の心を回復させることを優先して。今日できる小さなケアで十分だよ。"
        } else {
            analysis = engine.getAdvice(for: mode, count: 1).first ?? "もう少し具体的に、相手の行動・言葉・タイミングを教えて。脈あり度をかなり細かく読めるよ。"
        }

        return prefix + "\n\n" + analysis + "\n\n次の一手: 相手が返しやすい短い一言で、少しだけ距離を縮めてみて。"
    }

    private func screenshotMessages() -> [ChatMessage] {
        [
            ChatMessage(text: "脈あり判定をするね。相手の行動をできるだけ具体的に教えて。視線、返信、誘い方がヒントになるよ。", isUser: false),
            ChatMessage(text: "最近よく目が合うし、LINEも向こうから来ます", isUser: true),
            ChatMessage(text: "これはかなり良いサイン。目が合う回数が増えていて、さらに相手からLINEが来るなら、あなたに関心が向いている可能性は高めだよ。\n\n次の一手: いきなり告白より、短時間のお茶やランチに誘って反応を見てみて。", isUser: false),
            ChatMessage(text: "誘うならなんて送ればいい？", isUser: true),
            ChatMessage(text: "重くしないのがコツ。\n\n『この前話してたカフェ、今度軽く行かない？』くらいが自然。相手が日時を出してくれたら、脈あり度はさらに上がるよ。", isUser: false)
        ]
    }
    private func greetingForMode(_ mode: ConsultMode) -> String {
        switch mode {
        case .kataomoi:
            return "片思いの相談だね。相手の行動、LINE、会った時の雰囲気を教えて。脈ありサインを一緒に読み解くよ。"
        case .koibito:
            return "恋人関係の相談だね。不安な出来事や相手の言葉を、そのまま書いてみて。責めずに整理しよう。"
        case .myakuari:
            return "脈あり判定をするね。相手の行動をできるだけ具体的に教えて。視線、返信、誘い方がヒントになるよ。"
        case .line:
            return "LINE相談だね。相手の返信文、頻度、既読から返るまでの時間を教えて。温度感を読むよ。"
        case .shitsuren:
            return "失恋ケアだね。今の気持ちをそのまま書いて大丈夫。まずは心を軽くするところから。"
        case .shuraba:
            return "複雑な状況だね。事実と気持ちを分けながら、次に何を守るべきか整理しよう。"
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
        HStack(alignment: .bottom, spacing: 9) {
            if message.isUser { Spacer(minLength: 44) }

            if !message.isUser {
                Image("RomanceGuide")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MyakuariTheme.rose.opacity(0.7), lineWidth: 1.5))
            }

            Text(message.text)
                .font(.body)
                .lineSpacing(4)
                .foregroundStyle(message.isUser ? .white : MyakuariTheme.cream)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(message.isUser ? MyakuariTheme.rose.opacity(0.88) : Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(message.isUser ? Color.white.opacity(0.18) : MyakuariTheme.stroke, lineWidth: 1)
                )

            if !message.isUser { Spacer(minLength: 44) }
        }
    }
}

struct ThinkingBubble: View {
    @State private var dot = 0

    var body: some View {
        HStack(spacing: 9) {
            Image("RomanceGuide")
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(MyakuariTheme.rose.opacity(dot == i ? 1 : 0.25))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.12)))
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                dot = (dot + 1) % 3
            }
        }
    }
}
