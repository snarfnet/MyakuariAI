import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: ConsultHistory

    var body: some View {
        NavigationStack {
            ZStack {
                MyakuariBackground()

                if history.sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "相談履歴", subtitle: "前の気持ちと診断結果を見返せます")

                            ForEach(history.sessions) { session in
                                HistoryDetailRow(session: session)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            GradientIcon(systemName: "clock.arrow.circlepath", size: 70)
            VStack(spacing: 8) {
                Text("まだ相談履歴はありません")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                Text("相談や診断をすると、ここに保存されます。")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MyakuariTheme.softText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(26)
    }
}

struct HistoryDetailRow: View {
    let session: ConsultSession

    var body: some View {
        GlassPanel(radius: 22) {
            HStack(spacing: 14) {
                GradientIcon(systemName: session.mode.icon, size: 48)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(session.mode.rawValue)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(session.dateLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }

                    if let pct = session.diagnosisPercent {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("脈あり度")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MyakuariTheme.softText)
                                Spacer()
                                Text("\(pct)%")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(MyakuariTheme.rose)
                            }
                            ProgressView(value: Double(pct), total: 100)
                                .tint(MyakuariTheme.rose)
                        }
                    } else {
                        Text(session.preview)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MyakuariTheme.softText)
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
        }
    }
}
