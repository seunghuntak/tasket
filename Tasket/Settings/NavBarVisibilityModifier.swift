import SwiftUI

struct NavBarVisibilityModifier: ViewModifier {
    @AppStorage(AppSettings.hideNavBarWhenSwipeViewsOnKey) private var hideNavBarWhenSwipeOn: Bool = false

    func body(content: Content) -> some View {
        content
            .navigationBarHidden(hideNavBarWhenSwipeOn)
            .toolbar(hideNavBarWhenSwipeOn ? .hidden : .visible, for: .navigationBar)
    }
}

extension View {
    func applyNavBarVisibilitySetting() -> some View {
        self.modifier(NavBarVisibilityModifier())
    }
}
