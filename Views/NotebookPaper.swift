import SwiftUI

struct NotebookPaper: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack(alignment: .topLeading) {
                shape
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.96))

                Canvas { context, size in
                    var blueLines = Path()
                    let spacing: CGFloat = 31
                    for y in stride(from: 92, through: size.height - 24, by: spacing) {
                        blueLines.move(to: CGPoint(x: 0, y: y))
                        blueLines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(
                        blueLines,
                        with: .color(Color(red: 0.31, green: 0.55, blue: 0.82).opacity(0.18)),
                        lineWidth: 1
                    )

                    var redMargin = Path()
                    let marginX = min(max(size.width * 0.11, 48), 78)
                    redMargin.move(to: CGPoint(x: marginX, y: 76))
                    redMargin.addLine(to: CGPoint(x: marginX, y: size.height))
                    context.stroke(
                        redMargin,
                        with: .color(Color(red: 0.98, green: 0.34, blue: 0.36).opacity(0.24)),
                        lineWidth: 1
                    )
                }
                .clipShape(shape)

                LinearGradient(
                    colors: [
                        .white.opacity(0.20),
                        .clear,
                        .black.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)

                shape
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.16), radius: 28, y: 16)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
