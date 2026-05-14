import AppKit
import SwiftUI

struct PunaiseLogo: View {
    var size: CGFloat = 34

    var body: some View {
        Group {
            if let image = PunaiseIconLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            } else {
                fallbackMark
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Punaise")
    }

    private var fallbackMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(Color(red: 1.0, green: 0.78, blue: 0.26))
                .frame(width: size * 0.68, height: size * 0.68)
                .offset(x: -size * 0.11, y: size * 0.11)
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)

            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
                .frame(width: size * 0.68, height: size * 0.68)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                        .stroke(Color(red: 0.08, green: 0.23, blue: 0.42), lineWidth: max(2, size * 0.06))
                )
                .offset(x: size * 0.11, y: -size * 0.11)
        }
    }
}

private enum PunaiseIconLoader {
    static let image: NSImage? = {
        if let url = Bundle.main.url(forResource: "PunaiseIcon1024", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let url = Bundle.module.url(forResource: "PunaiseIcon1024", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let url = Bundle.module.url(forResource: "PunaiseIcon1024", withExtension: "png", subdirectory: "Resources"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        return nil
    }()
}
