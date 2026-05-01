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
    case myakuari = "脈あり？"
    case line = "LINE相談"
    case shitsuren = "失恋"
    case shuraba = "修羅場"

    var icon: String {
        switch self {
        case .kataomoi:  return "heart"
        case .koibito:   return "heart.fill"
        case .myakuari:  return "questionmark.circle"
        case .line:      return "message"
        case .shitsuren: return "heart.slash"
        case .shuraba:   return "flame"
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

    var localizedName: String {
        if Locale.current.language.languageCode?.identifier == "ja" {
            return rawValue
        }
        switch self {
        case .kataomoi:  return "Crush"
        case .koibito:   return "Relationship"
        case .myakuari:  return "Signs?"
        case .line:      return "Texting"
        case .shitsuren: return "Heartbreak"
        case .shuraba:   return "Crisis"
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
        let relevant = categories.filter { mode.categoryIDs.contains($0.id) }
        var pool: [String] = relevant.flatMap { $0.advice }
        pool.shuffle()
        return Array(pool.prefix(count))
    }

    func analyzeMiaku(answers: [Int]) -> MiakuResult {
        // answers: array of 0-4 scores from quiz
        let total = answers.reduce(0, +)
        let maxScore = answers.count * 4
        let percentage = min(100, max(0, Int(Double(total) / Double(max(maxScore, 1)) * 100)))

        let level: MiakuLevel
        let psychology: String
        let nextSteps: [String]

        switch percentage {
        case 0..<25:
            level = .low
            psychology = NSLocalizedString("miaku_psych_low", comment: "")
            nextSteps = [
                NSLocalizedString("step_low_1", comment: ""),
                NSLocalizedString("step_low_2", comment: ""),
                NSLocalizedString("step_low_3", comment: ""),
            ]
        case 25..<50:
            level = .medium
            psychology = NSLocalizedString("miaku_psych_med", comment: "")
            nextSteps = [
                NSLocalizedString("step_med_1", comment: ""),
                NSLocalizedString("step_med_2", comment: ""),
                NSLocalizedString("step_med_3", comment: ""),
            ]
        case 50..<75:
            level = .high
            psychology = NSLocalizedString("miaku_psych_high", comment: "")
            nextSteps = [
                NSLocalizedString("step_high_1", comment: ""),
                NSLocalizedString("step_high_2", comment: ""),
                NSLocalizedString("step_high_3", comment: ""),
            ]
        default:
            level = .veryHigh
            psychology = NSLocalizedString("miaku_psych_very_high", comment: "")
            nextSteps = [
                NSLocalizedString("step_vhigh_1", comment: ""),
                NSLocalizedString("step_vhigh_2", comment: ""),
                NSLocalizedString("step_vhigh_3", comment: ""),
            ]
        }

        let advice = getAdvice(for: .myakuari, count: 2)

        return MiakuResult(
            percentage: percentage,
            level: level,
            psychology: psychology,
            nextSteps: nextSteps,
            advice: advice
        )
    }
}

enum MiakuLevel {
    case low, medium, high, veryHigh

    var color: String {
        switch self {
        case .low:      return "gray"
        case .medium:   return "orange"
        case .high:     return "pink"
        case .veryHigh: return "red"
        }
    }

    var label: String {
        switch self {
        case .low:      return "まだこれから"
        case .medium:   return "ちょっと気になってるかも"
        case .high:     return "かなり脈あり！"
        case .veryHigh: return "ほぼ確実に好意あり！"
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
