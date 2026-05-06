import Foundation

struct ConsultSession: Identifiable, Codable {
    let id: String
    let modeRaw: String
    let preview: String
    let date: Date
    let diagnosisPercent: Int?

    var mode: ConsultMode { ConsultMode(rawValue: modeRaw) ?? .kataomoi }

    var dateLabel: String {
        let fmt = RelativeDateTimeFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: Date())
    }

    init(mode: ConsultMode, preview: String, diagnosisPercent: Int? = nil) {
        self.id = UUID().uuidString
        self.modeRaw = mode.rawValue
        self.preview = preview
        self.date = Date()
        self.diagnosisPercent = diagnosisPercent
    }
}

class ConsultHistory: ObservableObject {
    @Published var sessions: [ConsultSession] = []
    private let key = "myakuari_history"

    init() { load() }

    func save(mode: ConsultMode, messages: [ChatMessage]) {
        let userMsgs = messages.filter(\.isUser)
        let preview = userMsgs.last?.text ?? "相談メモ"
        if let idx = sessions.firstIndex(where: {
            $0.mode == mode && Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.diagnosisPercent == nil
        }) {
            sessions[idx] = ConsultSession(mode: mode, preview: preview)
        } else {
            sessions.insert(ConsultSession(mode: mode, preview: preview), at: 0)
        }
        if sessions.count > 50 { sessions = Array(sessions.prefix(50)) }
        persist()
    }

    func saveDiagnosis(percentage: Int) {
        sessions.insert(
            ConsultSession(mode: .myakuari, preview: "脈あり度: \(percentage)%", diagnosisPercent: percentage),
            at: 0
        )
        if sessions.count > 50 { sessions = Array(sessions.prefix(50)) }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ConsultSession].self, from: data) else { return }
        sessions = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
