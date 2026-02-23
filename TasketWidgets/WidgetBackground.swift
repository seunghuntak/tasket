import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.padding()
                .background(Color(.systemBackground))
        }
    }
}