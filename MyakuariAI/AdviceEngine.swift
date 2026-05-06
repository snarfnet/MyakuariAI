import Foundation

struct AdviceCategory: Codable, Identifiable {
    let id: String
    let name_en: String
    let name_ja: String
    let advice: [String]
}

enum ConsultMode: String, CaseIterable {
    case kataomoi = "片思い"
    case koibito = "恋人関係"
    case myakuari = "脈あり判定"
    case line = "LINE相談"
    case shitsuren = "失恋ケア"
    case shuraba = "修羅場整理"

    var icon: String {
        switch self {
        case .kataomoi:  return "heart"
        case .koibito:   return "heart.fill"
        case .myakuari:  return "sparkles"
        case .line:      return "message.fill"
        case .shitsuren: return "heart.slash.fill"
        case .shuraba:   return "flame.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .kataomoi:  return "気になる人への一歩を整理"
        case .koibito:   return "恋人との違和感を相談"
        case .myakuari:  return "行動から好意を分析"
        case .line:      return "返信・既読・温度感を読む"
        case .shitsuren: return "つらさを軽くする言葉"
        case .shuraba:   return "複雑な状況を冷静に分解"
        }
    }

    var tone: String {
        switch self {
        case .kataomoi:  return "gentle"
        case .koibito:   return "warm"
        case .myakuari:  return "analytical"
        case .line:      return "practical"
        case .shitsuren: return "comforting"
        case .shuraba:   return "direct"
        }
    }

    var categoryIDs: [String] {
        switch self {
        case .kataomoi:  return ["crush", "confession", "confidence"]
        case .koibito:   return ["lasting", "intimacy", "marriage"]
        case .myakuari:  return ["crush", "confession", "first_date"]
        case .line:      return ["crush", "confession", "dating_apps"]
        case .shitsuren: return ["heartbreak", "confidence", "getting_back"]
        case .shuraba:   return ["getting_back", "heartbreak", "lasting"]
        }
    }
}

@MainActor
class AdviceEngine: ObservableObject {
    @Published var categories: [AdviceCategory] = []

    init() {
        loadAdvice()
    }

    private func loadAdvice() {
        guard let url = Bundle.main.url(forResource: "advice_db", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AdviceCategory].self, from: data) else {
            return
        }
        categories = decoded
    }

    func getAdvice(for mode: ConsultMode, count: Int = 3) -> [String] {
        let defaults = japaneseAdvice(for: mode)
        return Array(defaults.shuffled().prefix(count))
    }

    private func japaneseAdvice(for mode: ConsultMode) -> [String] {
        switch mode {
        case .kataomoi:
            return [
                "相手の反応を一つだけで決めつけず、会話の続き方や表情をセットで見てみよう。",
                "好意は急に伝えるより、安心感を積み上げたあとに少しだけ踏み込むのが自然。",
                "次に会った時は、相手が答えやすい小さな質問から距離を縮めてみて。"
            ]
        case .koibito:
            return [
                "不安をぶつける前に、何が寂しかったのかを短く言葉にしてみよう。",
                "相手を責める言い方より、『私はこう感じた』で話すと受け取られやすいよ。",
                "仲直りは正しさより温度感。まずは落ち着いた時間を選んで。"
            ]
        case .myakuari:
            return [
                "脈ありは、視線・返信・会う理由の三つがそろうほど強くなるよ。",
                "相手から質問が増えているなら、あなたをもっと知りたいサインかも。",
                "二人きりの時間を嫌がらないなら、関係が進む余地はかなりあるよ。"
            ]
        case .line:
            return [
                "返信速度よりも、内容の濃さと質問が返ってくるかを見てみよう。",
                "短文でも会話を終わらせない返しなら、興味が残っている可能性があるよ。",
                "追いLINEは一度待って、相手が返しやすい軽い話題に変えるのが安全。"
            ]
        case .shitsuren:
            return [
                "今は答えを急がなくて大丈夫。まずは眠る、食べる、話すを取り戻そう。",
                "忘れようとしすぎるほど苦しくなるから、今日は少しだけ距離を置けたら十分。",
                "あなたの価値は、相手の返事や選択だけで決まらないよ。"
            ]
        case .shuraba:
            return [
                "感情が強い時ほど、事実・推測・希望を分けて書き出してみよう。",
                "すぐ結論を出すより、まず安全に話せる場所と時間を確保して。",
                "相手を動かすより、自分が守りたいラインを決めるのが先。"
            ]
        }
    }

    func analyzeMiaku(answers: [Int]) -> MiakuResult {
        let total = answers.reduce(0, +)
        let maxScore = answers.count * 4
        let percentage = min(100, max(0, Int(Double(total) / Double(max(maxScore, 1)) * 100)))

        let level: MiakuLevel
        let psychology: String
        let nextSteps: [String]

        switch percentage {
        case 0..<25:
            level = .low
            psychology = "今はまだ友達寄りの距離感。焦って押すより、相手が安心して話せる空気を作るのが先だよ。"
            nextSteps = ["共通の話題を一つ増やす", "グループで会う機会を作る", "返信を急かさず温度を合わせる"]
        case 25..<50:
            level = .medium
            psychology = "興味の芽はありそう。ただし確信には少し早い段階。相手の反応が続くかを丁寧に見てみよう。"
            nextSteps = ["軽い相談や質問を投げてみる", "相手の好きなものに反応する", "短時間のお茶に誘える流れを探す"]
        case 50..<75:
            level = .high
            psychology = "好意を持たれている可能性は高め。あなたを意識していて、もっと近づきたい気持ちがありそう。"
            nextSteps = ["具体的な日時で誘ってみる", "二人きりの会話を少し増やす", "自分の好意を小さく匂わせる"]
        default:
            level = .veryHigh
            psychology = "かなり脈あり。相手の行動に特別感が出ているので、次の一歩を待っている可能性もあるよ。"
            nextSteps = ["デートに自然に誘う", "好意をまっすぐ伝える準備をする", "曖昧にせず関係を進める"]
        }

        return MiakuResult(
            percentage: percentage,
            level: level,
            psychology: psychology,
            nextSteps: nextSteps,
            advice: getAdvice(for: .myakuari, count: 2)
        )
    }
}

enum MiakuLevel {
    case low, medium, high, veryHigh

    var label: String {
        switch self {
        case .low:      return "まだこれから"
        case .medium:   return "少し気になる存在"
        case .high:     return "かなり脈あり"
        case .veryHigh: return "ほぼ本命サイン"
        }
    }
}

struct MiakuResult {
    let percentage: Int
    let level: MiakuLevel
    let psychology: String
    let nextSteps: [String]
    let advice: [String]
}
