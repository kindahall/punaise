import SwiftUI

struct OnboardingView: View {
    let onRequestNotifications: () -> Void
    let onCreateFirstPunaise: () -> Void
    let onFinish: () -> Void

    @State private var step = 0
    @State private var didRequestNotifications = false
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue

    private let steps = OnboardingStep.allCases

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PunaiseLogo(size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Punaise")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Épingle ce qui presse.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                LanguageToggleButton()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer(minLength: 18)

            OnboardingStepView(
                step: steps[step],
                didRequestNotifications: didRequestNotifications,
                onRequestNotifications: {
                    didRequestNotifications = true
                    onRequestNotifications()
                },
                onCreateFirstPunaise: onCreateFirstPunaise
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 40)

            Spacer(minLength: 18)

            HStack {
                StepDots(count: steps.count, selection: step)

                Spacer()

                Button(PunaiseL10n.string("Passer")) {
                    onFinish()
                }
                .buttonStyle(BouncyPlainButtonStyle())
                .foregroundStyle(.secondary)

                Button(PunaiseL10n.string(step == steps.count - 1 ? "Commencer" : "Suivant")) {
                    if step == steps.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            step += 1
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(width: 680, height: 480)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 1.0, green: 0.86, blue: 0.52).opacity(0.22),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .punaiseLocale(language)
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep
    let didRequestNotifications: Bool
    let onRequestNotifications: () -> Void
    let onCreateFirstPunaise: () -> Void

    var body: some View {
        HStack(spacing: 36) {
            visual
                .frame(width: 230, height: 170)

            VStack(alignment: .leading, spacing: 14) {
                Label(step.kicker, systemImage: step.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(step.accent)

                Text(step.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(red: 0.08, green: 0.22, blue: 0.40))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(step.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if step == .notifications {
                    Button(PunaiseL10n.string(didRequestNotifications ? "Demande envoyée" : "Autoriser")) {
                        onRequestNotifications()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(didRequestNotifications)
                    .padding(.top, 4)
                }

                if step == .firstPunaise {
                    Button {
                        onCreateFirstPunaise()
                    } label: {
                        Label(PunaiseL10n.string("Créer ma première Punaise"), systemImage: "pin.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var visual: some View {
        switch step {
        case .promise:
            ZStack {
                StickyCardView(
                    reminder: Reminder(
                        title: PunaiseL10n.string("Envoyer contrat"),
                        note: "",
                        deadline: Date().addingTimeInterval(45 * 60),
                        urgency: .urgent,
                        isPinned: true
                    ),
                    scale: .preview
                )
                .frame(width: 210, height: 135)
                .rotationEffect(.degrees(-4))
            }
        case .notifications:
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.08)))
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.red)
                    Text(PunaiseL10n.string("Punaise critique"))
                        .font(.system(size: 18, weight: .bold))
                    Text(PunaiseL10n.string("Une échéance arrive."))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        case .shortcut:
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    KeyCap("⌃")
                    KeyCap("⌥")
                    KeyCap("P")
                }
                Text(PunaiseL10n.string("Nouvelle Punaise"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        case .firstPunaise:
            ZStack {
                StickyCardView(
                    reminder: Reminder(
                        title: PunaiseL10n.string("Ma première Punaise"),
                        note: "",
                        deadline: Date().addingTimeInterval(2 * 60 * 60),
                        urgency: .urgent,
                        isPinned: true
                    ),
                    scale: .preview
                )
                .frame(width: 210, height: 135)
                .rotationEffect(.degrees(3))
            }
        }
    }
}

private enum OnboardingStep: CaseIterable {
    case promise
    case notifications
    case shortcut
    case firstPunaise

    var kicker: String {
        switch self {
        case .promise:
            return PunaiseL10n.string("Urgence visible")
        case .notifications:
            return "macOS"
        case .shortcut:
            return PunaiseL10n.string("Raccourci")
        case .firstPunaise:
            return PunaiseL10n.string("Départ")
        }
    }

    var title: String {
        switch self {
        case .promise:
            return PunaiseL10n.string("Punaise rend l’urgence visible.")
        case .notifications:
            return PunaiseL10n.string("Sois prévenu avant le noir.")
        case .shortcut:
            return PunaiseL10n.string("Capture une urgence sans changer d’écran.")
        case .firstPunaise:
            return PunaiseL10n.string("Épingle ce qui ne peut pas attendre.")
        }
    }

    var subtitle: String {
        switch self {
        case .promise:
            return PunaiseL10n.string("Une Punaise commence calme, puis attire ton attention à mesure que l’échéance approche.")
        case .notifications:
            return PunaiseL10n.string("Les notifications complètent le bureau quand une Punaise devient critique.")
        case .shortcut:
            return PunaiseL10n.string("Ctrl + Option + P crée une Punaise rapide depuis n’importe où.")
        case .firstPunaise:
            return PunaiseL10n.string("Crée une Punaise test et laisse-la vivre sur ton bureau.")
        }
    }

    var systemImage: String {
        switch self {
        case .promise:
            return "pin.fill"
        case .notifications:
            return "bell.badge"
        case .shortcut:
            return "keyboard"
        case .firstPunaise:
            return "plus.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .promise:
            return .orange
        case .notifications:
            return .red
        case .shortcut:
            return .blue
        case .firstPunaise:
            return .green
        }
    }
}

private struct StepDots: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? Color.orange : Color.secondary.opacity(0.22))
                    .frame(width: index == selection ? 22 : 7, height: 7)
            }
        }
    }
}

private struct KeyCap: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .bold))
            .frame(width: 58, height: 54)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black.opacity(0.12))
            )
            .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
    }
}
