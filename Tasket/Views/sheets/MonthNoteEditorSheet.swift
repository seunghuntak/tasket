import SwiftUI
import SwiftData

struct MonthNoteEditorSheet: View {
    let monthKey: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var notes: [MonthNote]
    @State private var text: String = ""

    init(monthKey: String) {
        self.monthKey = monthKey
        _notes = Query(filter: #Predicate<MonthNote> { $0.monthKey == monthKey })
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                Spacer()
            }
            .navigationTitle("Monthly Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                text = notes.first?.text ?? ""
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = notes.first {
            existing.text = trimmed
            existing.updatedAt = .now
        } else {
            // Only create if user actually wrote something
            guard !trimmed.isEmpty else { return }
            modelContext.insert(MonthNote(monthKey: monthKey, text: trimmed))
        }
    }
}
