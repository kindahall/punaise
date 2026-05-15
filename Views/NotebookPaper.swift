import SwiftUI

struct NotebookPaper: View {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let theme = PunaiseTheme(colorScheme: colorScheme)
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack(alignment: .topLeading) {
                shape
                    .fill(theme.editorSurface)

                shape
                    .fill(.regularMaterial)
                    .opacity(theme.isDark ? 0.35 : 0)

                Canvas { context, size in
                    var fineLines = Path()
                    let spacing: CGFloat = 44
                    for y in stride(from: 22, through: size.height, by: spacing) {
                        fineLines.move(to: CGPoint(x: 0, y: y))
                        fineLines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(
                        fineLines,
                        with: .color((theme.isDark ? Color.white : theme.linkBlue).opacity(theme.isDark ? 0.030 : 0.018)),
                        lineWidth: 1
                    )

                    var verticalLines = Path()
                    for x in stride(from: 34, through: size.width, by: spacing) {
                        verticalLines.move(to: CGPoint(x: x, y: 0))
                        verticalLines.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(
                        verticalLines,
                        with: .color((theme.isDark ? Color.white : Color.black).opacity(theme.isDark ? 0.020 : 0.012)),
                        lineWidth: 1
                    )
                }
                .clipShape(shape)

                LinearGradient(
                    colors: [
                        .white.opacity(theme.isDark ? 0.045 : 0.30),
                        .clear,
                        .black.opacity(theme.isDark ? 0.18 : 0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(theme.isDark ? 1 : 0)
                .clipShape(shape)

                shape
                    .stroke(theme.hairline, lineWidth: 1)
            }
            .shadow(color: theme.shadow, radius: theme.isDark ? 36 : 28, y: 16)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
