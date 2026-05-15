import SwiftUI

struct UrgencySelector: View {
    @Binding var selection: Urgency
    let status: ReminderStatus

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Urgency.allCases) { urgency in
                Button {
                    selection = urgency
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: urgency.systemImage)
                        Text(urgency.title)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selection == urgency ? foreground(for: urgency) : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.97))
                .background(background(for: urgency))
                .overlay(
                    Rectangle()
                        .fill(.black.opacity(0.08))
                        .frame(width: urgency == .relaxed ? 0 : 1),
                    alignment: .trailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(status == .critical ? .red.opacity(0.45) : .black.opacity(0.10))
        )
    }

    private func background(for urgency: Urgency) -> Color {
        guard selection == urgency else { return .clear }

        switch urgency {
        case .urgent:
            return Color.red.opacity(0.13)
        case .neutral:
            return Color.blue.opacity(0.11)
        case .relaxed:
            return Color.green.opacity(0.12)
        }
    }

    private func foreground(for urgency: Urgency) -> Color {
        switch urgency {
        case .urgent:
            return .red
        case .neutral:
            return .blue
        case .relaxed:
            return .green
        }
    }
}

struct StatusPill: View {
    let status: ReminderStatus

    var body: some View {
        Label(status.title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25)))
    }

    private var icon: String {
        switch status {
        case .calm:
            return "leaf"
        case .watching:
            return "eye"
        case .pressing:
            return "flame"
        case .critical:
            return "bell.badge"
        case .overdue:
            return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .calm:
            return .green
        case .watching:
            return .yellow
        case .pressing:
            return .orange
        case .critical:
            return .red
        case .overdue:
            return .black
        }
    }
}

struct EmptyStateView: View {
    let onCreate: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(spacing: 18) {
            PunaiseLogo(size: 54)
            Text("Punaise")
                .font(.system(size: 34, weight: .semibold))
            Text("Épingle ce qui presse.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Button(action: onCreate) {
                Label("Créer une Punaise", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .foregroundStyle(theme.brand)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                theme.accent.opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18))
            )
            .shadow(color: theme.accent.opacity(configuration.isPressed ? 0.08 : 0.20), radius: configuration.isPressed ? 4 : 9, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.91 : 1)
            .animation(.interpolatingSpring(stiffness: 360, damping: 18), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.brand)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                theme.inputSurface.opacity(configuration.isPressed ? 1.45 : 1),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(theme.hairline)
            )
            .shadow(color: theme.shadow.opacity(configuration.isPressed ? 0.18 : 0.35), radius: configuration.isPressed ? 3 : 7, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.91 : 1)
            .animation(.interpolatingSpring(stiffness: 360, damping: 18), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var isActive = false
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        configuration.label
            .foregroundStyle(isActive ? theme.linkBlue : .secondary)
            .background(
                (isActive ? theme.selectedSurface : theme.inputSurface)
                    .opacity(configuration.isPressed ? 0.60 : 1),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isActive ? theme.linkBlue.opacity(0.26) : theme.hairline)
            )
            .shadow(color: (isActive ? theme.linkBlue : theme.shadow).opacity(configuration.isPressed ? 0.03 : 0.12), radius: configuration.isPressed ? 2 : 7, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.84 : 1)
            .animation(.interpolatingSpring(stiffness: 420, damping: 17), value: configuration.isPressed)
    }
}

struct BouncyPlainButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.90

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.interpolatingSpring(stiffness: 420, damping: 16), value: configuration.isPressed)
    }
}

struct AppearanceToggleButton: View {
    @AppStorage(PunaisePreferenceKey.appearance) private var appearance = PunaiseAppearancePreference.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = currentIsDark
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let nextTitle = isDark ? "clair" : "sombre"

        Button {
            withAnimation(.interpolatingSpring(stiffness: 360, damping: 22)) {
                appearance = isDark ? PunaiseAppearancePreference.light.rawValue : PunaiseAppearancePreference.dark.rawValue
            }
        } label: {
            Image(systemName: isDark ? "sun.max" : "moon")
                .frame(width: 30, height: 30)
                .foregroundStyle(isDark ? theme.urgencyYellow : theme.linkBlue)
                .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(theme.hairline)
                )
        }
        .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
        .help("Passer en mode \(nextTitle)")
    }

    private var currentIsDark: Bool {
        let selected = PunaiseAppearancePreference.value(from: appearance)

        switch selected {
        case .system:
            return colorScheme == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
}

struct LanguageToggleButton: View {
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let current = PunaiseLanguage.value(from: language)
        let theme = PunaiseTheme(colorScheme: colorScheme)

        Button {
            let nextLanguage = current.next
            withAnimation(.interpolatingSpring(stiffness: 360, damping: 22)) {
                language = nextLanguage.rawValue
            }
            NotificationCenter.default.post(name: .punaiseLanguageDidChange, object: nil)
        } label: {
            Text(current.next.shortTitle)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30)
                .foregroundStyle(theme.brand)
                .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(theme.hairline)
                )
        }
        .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
        .help(current == .french ? "Switch to English" : "Passer en français")
    }
}
