import SwiftUI

struct FloatingControls: View {
    let onSettings: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 10)
        .padding(.trailing, 14)
    }
}
