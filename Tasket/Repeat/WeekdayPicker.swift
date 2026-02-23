import SwiftUI

struct WeekdayPicker: View {
    @Binding var selected: Set<Int> // 1=Sun ... 7=Sat

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat on")
                .font(.caption)
                .foregroundStyle(.secondary)

            let symbols = calendar.shortStandaloneWeekdaySymbols // ["Sun","Mon",...]
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let weekday = i + 1
                    let isOn = selected.contains(weekday)

                    Button {
                        if isOn { selected.remove(weekday) } else { selected.insert(weekday) }
                    } label: {
                        Text(symbols[i])
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(isOn ? Color.primary.opacity(0.15) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
