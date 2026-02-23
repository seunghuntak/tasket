import SwiftUI

struct TaskEditorPrefillDateSheet: View {
    let prefillDate: Date

    var body: some View {
        TaskEditorSheetWithPrefill(taskToEdit: nil, prefillDate: prefillDate)
    }
}
