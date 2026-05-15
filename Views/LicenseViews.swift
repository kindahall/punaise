import SwiftUI

struct LicenseStatusBadge: View {
    let isPro: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        Label(isPro ? PunaiseL10n.string("Pro activé") : PunaiseL10n.string("Version gratuite"), systemImage: isPro ? "sparkles" : "lock.open")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isPro ? Color.orange : theme.brand)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((isPro ? Color.orange.opacity(0.12) : theme.inputSurface), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isPro ? Color.orange.opacity(0.24) : theme.hairline)
            )
    }
}

struct FreeUsageCard: View {
    let activeCount: Int
    let onShowLicense: (PunaiseProFeature) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let clampedProgress = min(1, CGFloat(activeCount) / CGFloat(PunaiseLicense.freeActiveLimit))

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LicenseStatusBadge(isPro: false)
                Spacer()
                Text("\(activeCount)/\(PunaiseLicense.freeActiveLimit)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(activeCount >= PunaiseLicense.freeActiveLimit ? .orange : .secondary)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.hoverSurface)
                    Capsule()
                        .fill(activeCount >= PunaiseLicense.freeActiveLimit ? Color.orange : theme.accent)
                        .frame(width: proxy.size.width * clampedProgress)
                }
            }
            .frame(height: 7)

            Text(PunaiseL10n.string("La version gratuite garde 5 Punaises actives."))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onShowLicense(.unlimitedPunaises)
            } label: {
                Label("Débloquer Pro", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(12)
        .background(theme.panelSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(theme.hairline)
        )
        .padding(.horizontal, 20)
    }
}

struct ProLockCard: View {
    let feature: PunaiseProFeature
    var compact = false
    let onShowLicense: (PunaiseProFeature) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        HStack(alignment: compact ? .center : .top, spacing: 12) {
            Image(systemName: feature.systemImage)
                .font(.system(size: compact ? 14 : 18, weight: .bold))
                .foregroundStyle(.orange)
                .frame(width: compact ? 24 : 32, height: compact ? 24 : 32)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: compact ? 7 : 9, style: .continuous))

            VStack(alignment: .leading, spacing: compact ? 2 : 5) {
                Text(feature.title)
                    .font(.system(size: compact ? 12 : 14, weight: .bold))
                    .foregroundStyle(theme.brand)
                    .lineLimit(1)

                Text(feature.detail)
                    .font(.system(size: compact ? 11 : 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                onShowLicense(feature)
            } label: {
                Label(compact ? "Pro" : "Débloquer Pro", systemImage: "sparkles")
                    .fixedSize()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(compact ? 10 : 12)
        .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                .stroke(Color.orange.opacity(0.20))
        )
    }
}

struct LicenseActivationSheet: View {
    let feature: PunaiseProFeature?
    @Binding var isPresented: Bool
    @AppStorage(PunaisePreferenceKey.licenseKey) private var storedLicenseKey = ""
    @State private var draftKey = ""
    @State private var message: String?
    @Environment(\.colorScheme) private var colorScheme

    private var isPro: Bool {
        PunaiseLicense.isValid(storedLicenseKey)
    }

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isPro ? "sparkles" : "lock")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isPro ? .orange : theme.brand)
                    .frame(width: 48, height: 48)
                    .background((isPro ? Color.orange.opacity(0.14) : theme.inputSurface), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(isPro ? "Pro activé" : "Entrer une clé Pro")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(theme.brand)

                    Text(feature?.detail ?? PunaiseL10n.string("La version gratuite garde 5 Punaises actives. Passe en Pro pour tout débloquer."))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let feature, !isPro {
                ProLockCard(feature: feature, compact: true) { _ in
                    PunaiseLicense.openPurchasePage()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Clé de licence")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)

                TextField("PUNAISE-XXXX-XXXX-XXXX", text: $draftKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .disabled(isPro)
            }

            if let message {
                Text(message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isPro ? .green : .red)
            }

            HStack(spacing: 10) {
                Button {
                    PunaiseLicense.openPurchasePage()
                } label: {
                    Label("Obtenir une clé", systemImage: "creditcard")
                }
                .buttonStyle(SecondaryButtonStyle())

                Spacer()

                Button("Annuler") {
                    isPresented = false
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    activate()
                } label: {
                    Label(isPro ? "Pro activé" : "Activer Pro", systemImage: isPro ? "checkmark.seal.fill" : "key")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPro || draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(theme.windowBase)
        .onAppear {
            draftKey = storedLicenseKey
        }
    }

    private func activate() {
        let normalized = PunaiseLicense.normalizedKey(draftKey)
        guard PunaiseLicense.isValid(normalized) else {
            message = PunaiseL10n.string("Clé invalide.")
            return
        }

        storedLicenseKey = normalized
        message = PunaiseL10n.string("Licence activée.")
        NotificationCenter.default.post(name: .punaiseLicenseDidChange, object: nil)
        isPresented = false
    }
}

struct LicenseInlineActivationView: View {
    @AppStorage(PunaisePreferenceKey.licenseKey) private var storedLicenseKey = ""
    @State private var draftKey = ""
    @State private var message: String?

    private var isPro: Bool {
        PunaiseLicense.isValid(storedLicenseKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LicenseStatusBadge(isPro: isPro)
                Spacer()
                Button {
                    PunaiseLicense.openPurchasePage()
                } label: {
                    Label("Obtenir une clé", systemImage: "creditcard")
                }
            }

            Text(isPro ? PunaiseL10n.string("Toutes les fonctions Pro sont débloquées sur ce Mac.") : PunaiseL10n.string("Colle ta clé après le paiement Stripe pour passer de Gratuit à Pro."))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                TextField("PUNAISE-XXXX-XXXX-XXXX", text: $draftKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .disabled(isPro)

                Button("Activer Pro") {
                    activate()
                }
                .disabled(isPro || draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message {
                Text(message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isPro ? .green : .red)
            }
        }
        .onAppear {
            draftKey = storedLicenseKey
        }
    }

    private func activate() {
        let normalized = PunaiseLicense.normalizedKey(draftKey)
        guard PunaiseLicense.isValid(normalized) else {
            message = PunaiseL10n.string("Clé invalide.")
            return
        }

        storedLicenseKey = normalized
        message = PunaiseL10n.string("Licence activée.")
        NotificationCenter.default.post(name: .punaiseLicenseDidChange, object: nil)
    }
}
