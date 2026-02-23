import SwiftUI

struct MonthDayCell: View {
    let date: Date
    let isInDisplayedMonth: Bool
    let incompleteCount: Int
    let completeCount: Int
    let incompleteDotColor: Color

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(String(Calendar.current.component(.day, from: date)))
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(isInDisplayedMonth ? .primary : .secondary)

            tokenGrid
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? incompleteDotColor : .clear, lineWidth: isToday ? 2 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isInDisplayedMonth ? 1.0 : 0.35)
    }

    // MARK: - Token System

    private enum Token {
        case dot(Color)         // 1 slot
        case shortDash(Color)   // 3 slots (5 tasks)
        case longDash(Color)    // 5 slots (10 tasks)
    }

    private var tokenGrid: some View {
        let tokens =
            makeTokens(color: incompleteDotColor, count: incompleteCount)
            + makeTokens(color: .gray, count: completeCount)

        let rows = makeRows(tokens: tokens, slotsPerRow: 5)

        return VStack(spacing: 3) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, token in
                        tokenView(token)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center) // center each row
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)  // adds space from left & right edges
        .padding(.top, 1)
    }

    // MARK: - Token Creation Logic

    /*
     10 tasks -> longDash (5 slots)
     5 tasks  -> shortDash (3 slots)
     remainder -> dots (1 slot each)
    */
    private func makeTokens(color: Color, count: Int) -> [Token] {
        guard count > 0 else { return [] }

        var remaining = count
        var tokens: [Token] = []

        while remaining >= 10 {
            tokens.append(.longDash(color))
            remaining -= 10
        }

        while remaining >= 5 {
            tokens.append(.shortDash(color))
            remaining -= 5
        }

        while remaining > 0 {
            tokens.append(.dot(color))
            remaining -= 1
        }

        return tokens
    }

    // MARK: - Layout Engine (5 slots per row)

    private func makeRows(tokens: [Token], slotsPerRow: Int) -> [[Token]] {
        var rows: [[Token]] = []
        var currentRow: [Token] = []
        var usedSlots = 0

        func slotCost(_ token: Token) -> Int {
            switch token {
            case .dot: return 1
            case .shortDash: return 3
            case .longDash: return 5
            }
        }

        for token in tokens {
            let cost = slotCost(token)

            if usedSlots + cost > slotsPerRow {
                rows.append(currentRow)
                currentRow = [token]
                usedSlots = cost
            } else {
                currentRow.append(token)
                usedSlots += cost
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    // MARK: - Drawing

    private func tokenView(_ token: Token) -> some View {
        let dotSize: CGFloat = 5
        let spacing: CGFloat = 3

        switch token {

        case .dot(let color):
            return AnyView(
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .foregroundStyle(color)
            )

        case .shortDash(let color):
            let width = dotSize * 3 + spacing * 2
            return AnyView(
                RoundedRectangle(cornerRadius: dotSize / 2)
                    .frame(width: width, height: dotSize)
                    .foregroundStyle(color)
            )

        case .longDash(let color):
            let width = dotSize * 5 + spacing * 4
            return AnyView(
                RoundedRectangle(cornerRadius: dotSize / 2)
                    .frame(width: width, height: dotSize)
                    .foregroundStyle(color)
            )
        }
    }
}
