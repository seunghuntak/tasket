import SwiftUI

struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMonth: Date

    @State private var tempDate: Date

    init(selectedMonth: Binding<Date>) {
        _selectedMonth = selectedMonth
        _tempDate = State(initialValue: selectedMonth.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_US"))
            }
            .navigationTitle("Select Month")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedMonth = Calendar.current.startOfMonth(for: tempDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
