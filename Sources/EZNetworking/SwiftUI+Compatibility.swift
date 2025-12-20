#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Presents the subscription management sheet on supported platforms and OS versions.
    @ViewBuilder
    func manageSubscriptionsSheetCompat(isPresented: Binding<Bool>) -> some View {
        #if os(iOS) || os(visionOS)
        if #available(iOS 15.0, visionOS 1.0, *) {
            manageSubscriptionsSheet(isPresented: isPresented)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

public extension View {
    /// Applies a paging TabView style on supported platforms while leaving other platforms unchanged.
    @ViewBuilder
    func pageTabViewStyleCompat(
        indexDisplayMode: PageTabViewStyle.IndexDisplayMode = .automatic
    ) -> some View {
        #if os(iOS) || os(visionOS)
        tabViewStyle(.page(indexDisplayMode: indexDisplayMode))
        #else
        self
        #endif
    }
}
#endif
