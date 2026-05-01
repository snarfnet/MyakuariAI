import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: ConsultHistory

    var body: some View {
        NavigationStack {
            Group {
                if history.sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 44))
                            .foregroundStyle(.pink.opacity(0.3))
                        Text("相談履歴がここに表示されます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(history.sessions) { session in
                            HStack(spacing: 12) {
                                Image(systemName: session.mode.icon)
                                    .font(.title3)
                                    .foregroundStyle(.pink)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(session.mode.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(session.dateLabel)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }

                                    if let pct = session.diagnosisPercent {
                                        HStack(spacing: 6) {
                                            ProgressView(value: Double(pct), total: 100)
                                                .tint(.pink)
                                                .frame(width: 80)
                                            Text("\(pct)%")
                                                .font(.caption)
                                                .foregroundStyle(.pink)
                                        }
                                    } else {
                                        Text(session.preview)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { idx in
                            history.sessions.remove(atOffsets: idx)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("相談履歴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
