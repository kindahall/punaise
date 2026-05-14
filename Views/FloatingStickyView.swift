import SwiftUI

struct FloatingStickyView: View {
    let reminder: Reminder
    let onOpen: () -> Void
    let onUnpin: () -> Void

    var body: some View {
        StickyCardView(
            reminder: reminder,
            scale: .regular,
            showsControls: true,
            onOpen: onOpen,
            onUnpin: onUnpin
        )
        .frame(width: 286, height: 184)
        .padding(8)
    }
}
