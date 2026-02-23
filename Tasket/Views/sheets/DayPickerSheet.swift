import SwiftUI

struct DayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDay: Date

    @State private var tempDate: Date

    init(selectedDay: Binding<Date>) {
        _selectedDay = selectedDay
        _tempDate = State(initialValue: selectedDay.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $tempDate, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
            .navigationTitle("Select Day")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedDay = Calendar.current.startOfDay(for: tempDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
