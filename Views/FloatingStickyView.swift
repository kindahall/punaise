import SwiftUI

struct FloatingStickyView: View {
    let reminder: Reminder
    var appearsAnimated = false
    let onOpen: () -> Void
    let onUnpin: () -> Void

    @State private var isAppearing = false
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue

    var body: some View {
        StickyCardView(
            reminder: reminder,
            scale: .regular,
            showsControls: true,
            onOpen: onOpen,
            onUnpin: onUnpin
        )
        .frame(width: 286, height: 184)
        .padding(16)
        .punaiseLocale(language)
        .scaleEffect(appearsAnimated ? (isAppearing ? 1.0 : 0.58) : 1.0)
        .opacity(appearsAnimated ? (isAppearing ? 1.0 : 0.0) : 1.0)
        .rotationEffect(.degrees(appearsAnimated ? (isAppearing ? 0 : -5) : 0))
        .blur(radius: appearsAnimated && !isAppearing ? 3 : 0)
        .onAppear {
            guard appearsAnimated else {
                isAppearing = true
                return
            }

            isAppearing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.interpolatingSpring(stiffness: 260, damping: 16)) {
                    isAppearing = true
                }
            }
        }
    }
}
