import SwiftUI

struct StickyCardView: View {
    let reminder: Reminder
    var now: Date = Date()
    var scale: StickyScale = .regular
    var showsControls = false
    var onOpen: (() -> Void)?
    var onUnpin: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.55)) { context in
            let status = reminder.status(at: context.date)
            let stage = reminder.antiForgetStage(at: context.date)
            let score = reminder.pressureScore(at: context.date)
            let pulse = sin(context.date.timeIntervalSinceReferenceDate * 3.4)
            let vibration = sin(context.date.timeIntervalSinceReferenceDate * 22) * stage.vibrationAmplitude
            let palette = StickyPalette.palette(
                for: reminder.urgency,
                status: status,
                pulse: pulse,
                colorScheme: colorScheme
            )

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: scale.cornerRadius, style: .continuous)
                    .fill(palette.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: scale.cornerRadius, style: .continuous)
                            .stroke(palette.border, lineWidth: status == .critical || stage >= .halo ? 2 : 1)
                    )
                    .shadow(
                        color: palette.glow,
                        radius: CGFloat(status == .critical ? 22 : 11) * CGFloat(stage.haloMultiplier) + (isHovered ? scale.hoverShadowBoost : 0),
                        y: isHovered ? 18 : 8
                    )

                if stage >= .halo {
                    RoundedRectangle(cornerRadius: scale.cornerRadius + 4, style: .continuous)
                        .stroke(palette.accent.opacity(stage == .front ? 0.44 : 0.24), lineWidth: stage == .front ? 5 : 3)
                        .blur(radius: stage == .front ? 4 : 2)
                        .padding(-3)
                }

                if isHovered {
                    RoundedRectangle(cornerRadius: scale.cornerRadius + 3, style: .continuous)
                        .stroke(palette.accent.opacity(0.34), lineWidth: 2)
                        .padding(-3)
                        .transition(.opacity)
                }

                PaperFiberOverlay(cornerRadius: scale.cornerRadius, isDark: palette.isDark)

                LinearGradient(
                    colors: [.white.opacity(palette.isDark ? 0.05 : 0.22), .clear, .black.opacity(palette.isDark ? 0.12 : 0.025)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: scale.cornerRadius, style: .continuous))

                PinHeadView(status: status, scale: scale, pulse: pulse)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: -scale.pinOffset)

                VStack(alignment: .leading, spacing: scale.verticalSpacing) {
                    HStack(spacing: 8) {
                        Image(systemName: reminder.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: scale.captionSize, weight: .medium))
                            .foregroundStyle(palette.accent)

                        Text(PunaiseDateFormatting.relativeDeadline(reminder.deadline, now: context.date))
                            .font(.system(size: scale.captionSize, weight: .medium))
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(1)

                        if !reminder.attachments.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "paperclip")
                                Text("\(reminder.attachments.count)")
                            }
                            .font(.system(size: scale.captionSize, weight: .bold))
                            .foregroundStyle(palette.secondaryText)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(palette.secondaryText.opacity(0.10), in: Capsule())
                        }

                        PressureMiniBadge(score: score, palette: palette, scale: scale)

                        Spacer(minLength: 8)

                        if showsControls {
                            Button(action: { onUnpin?() }) {
                                Image(systemName: "pin.slash")
                                    .font(.system(size: scale.captionSize, weight: .semibold))
                            }
                            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.82))
                            .foregroundStyle(palette.secondaryText)
                            .help("Désépingler")
                        } else {
                            Image(systemName: "pin.fill")
                                .font(.system(size: scale.captionSize, weight: .medium))
                                .foregroundStyle(palette.secondaryText.opacity(0.80))
                        }
                    }

                    Spacer(minLength: 2)

                    Text(reminder.displayTitle)
                        .font(.system(size: scale.titleSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(scale.titleLines)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)

                    AntiForgetBadge(status: status, stage: stage, scale: scale, palette: palette)
                }
                .padding(scale.padding)
            }
            .contentShape(RoundedRectangle(cornerRadius: scale.cornerRadius, style: .continuous))
            .onHover { isHovered = $0 }
            .onTapGesture {
                onOpen?()
            }
            .scaleEffect(isHovered ? scale.hoverScale : 1.0)
            .offset(x: CGFloat(vibration), y: isHovered ? scale.hoverLift : 0)
            .rotationEffect(.degrees((status == .critical ? pulse * 0.35 : 0) + vibration * 0.12 + (isHovered ? scale.hoverRotation : 0)))
            .animation(.easeInOut(duration: 0.28), value: pulse)
            .animation(.interpolatingSpring(stiffness: 300, damping: 18), value: isHovered)
            .accessibilityLabel(reminder.displayTitle)
        }
    }
}

private struct PressureMiniBadge: View {
    let score: Int
    let palette: StickyPalette
    let scale: StickyScale

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text("\(score)")
                .monospacedDigit()
        }
        .font(.system(size: scale.captionSize, weight: .bold))
        .foregroundStyle(palette.accent)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(palette.accent.opacity(palette.isDark ? 0.16 : 0.12), in: Capsule())
    }
}

private struct AntiForgetBadge: View {
    let status: ReminderStatus
    let stage: AntiForgetStage
    let scale: StickyScale
    let palette: StickyPalette

    var body: some View {
        if status == .overdue {
            badge(PunaiseL10n.string("PUNAISE NOIRE"), color: Color(red: 1.0, green: 0.29, blue: 0.24))
        } else if status == .critical {
            badge(PunaiseL10n.string(stage >= .vibrate ? "ANTI-OUBLI" : "CRITIQUE"), color: palette.accent)
        } else if stage >= .halo {
            badge(stage.title.uppercased(), color: palette.accent)
        }
    }

    private func badge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: scale.captionSize, weight: .bold))
            .foregroundStyle(color)
            .padding(.top, 2)
    }
}

enum StickyScale {
    case regular
    case preview
    case mini

    var padding: CGFloat {
        switch self {
        case .regular:
            return 22
        case .preview:
            return 16
        case .mini:
            return 12
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular:
            return 14
        case .preview:
            return 12
        case .mini:
            return 10
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .regular:
            return 26
        case .preview:
            return 19
        case .mini:
            return 13
        }
    }

    var captionSize: CGFloat {
        switch self {
        case .regular:
            return 13
        case .preview:
            return 10
        case .mini:
            return 8
        }
    }

    var verticalSpacing: CGFloat {
        switch self {
        case .regular:
            return 10
        case .preview:
            return 6
        case .mini:
            return 4
        }
    }

    var titleLines: Int {
        switch self {
        case .regular:
            return 3
        case .preview:
            return 2
        case .mini:
            return 2
        }
    }

    var pinOffset: CGFloat {
        switch self {
        case .regular:
            return 8
        case .preview:
            return 7
        case .mini:
            return 5
        }
    }

    var hoverScale: CGFloat {
        switch self {
        case .regular:
            return 1.065
        case .preview:
            return 1.055
        case .mini:
            return 1.035
        }
    }

    var hoverLift: CGFloat {
        switch self {
        case .regular:
            return -7
        case .preview:
            return -5
        case .mini:
            return -2
        }
    }

    var hoverRotation: Double {
        switch self {
        case .regular:
            return 0.8
        case .preview:
            return 0.45
        case .mini:
            return 0.25
        }
    }

    var hoverShadowBoost: CGFloat {
        switch self {
        case .regular:
            return 18
        case .preview:
            return 12
        case .mini:
            return 6
        }
    }
}

private struct PinHeadView: View {
    let status: ReminderStatus
    let scale: StickyScale
    let pulse: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: metalColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: shadowColor, radius: status == .critical ? 6 + max(0, pulse) * 4 : 4, y: 2)

            Circle()
                .stroke(.white.opacity(status == .overdue ? 0.20 : 0.45), lineWidth: 1)

            Image(systemName: "pin.fill")
                .font(.system(size: diameter * 0.42, weight: .bold))
                .foregroundStyle(status == .critical ? .white : .white.opacity(0.82))
                .rotationEffect(.degrees(-18))
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(status == .critical ? 1 + max(0, pulse) * 0.05 : 1)
    }

    private var diameter: CGFloat {
        switch scale {
        case .regular:
            return 30
        case .preview:
            return 22
        case .mini:
            return 16
        }
    }

    private var metalColors: [Color] {
        switch status {
        case .critical:
            return [Color(red: 1.0, green: 0.42, blue: 0.38), Color(red: 0.62, green: 0.03, blue: 0.02)]
        case .overdue:
            return [Color(red: 0.20, green: 0.21, blue: 0.23), Color(red: 0.045, green: 0.047, blue: 0.052)]
        default:
            return [Color(red: 1.0, green: 0.68, blue: 0.25), Color(red: 0.88, green: 0.32, blue: 0.08)]
        }
    }

    private var shadowColor: Color {
        status == .critical ? .red.opacity(0.45) : .black.opacity(0.24)
    }
}

private struct PaperFiberOverlay: View {
    let cornerRadius: CGFloat
    let isDark: Bool

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Rectangle()
                    .fill((isDark ? Color.white : Color.black).opacity(isDark ? 0.025 : 0.035))
                    .frame(height: 0.7)
                    .offset(y: CGFloat(index * 22 - 58))
            }

            LinearGradient(
                colors: [
                    (isDark ? Color.white : Color.black).opacity(isDark ? 0.018 : 0.026),
                    .clear,
                    (isDark ? Color.black : Color.white).opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct StickyPalette {
    let background: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let border: Color
    let glow: Color
    let isDark: Bool

    static func palette(for urgency: Urgency, status: ReminderStatus, pulse: Double, colorScheme: ColorScheme) -> StickyPalette {
        let interfaceIsDark = colorScheme == .dark

        if status == .overdue {
            return StickyPalette(
                background: Color(red: 0.025, green: 0.028, blue: 0.030),
                primaryText: .white.opacity(0.94),
                secondaryText: .white.opacity(0.66),
                accent: Color(red: 1.0, green: 0.25, blue: 0.22),
                border: .white.opacity(0.10),
                glow: .black.opacity(0.38),
                isDark: true
            )
        }

        if status == .critical {
            let glowOpacity = 0.32 + max(0, pulse) * 0.26
            return StickyPalette(
                background: interfaceIsDark ? Color(red: 0.48, green: 0.055, blue: 0.050) : Color(red: 1.0, green: 0.25, blue: 0.20),
                primaryText: .white,
                secondaryText: .white.opacity(0.84),
                accent: .white,
                border: .white.opacity(0.42 + max(0, pulse) * 0.18),
                glow: Color(red: 1.0, green: 0.06, blue: 0.04).opacity(glowOpacity),
                isDark: true
            )
        }

        if status == .pressing {
            if interfaceIsDark {
                return StickyPalette(
                    background: Color(red: 0.34, green: 0.18, blue: 0.070),
                    primaryText: Color(red: 1.0, green: 0.94, blue: 0.84),
                    secondaryText: Color(red: 1.0, green: 0.82, blue: 0.58).opacity(0.78),
                    accent: Color(red: 1.0, green: 0.62, blue: 0.24),
                    border: Color(red: 1.0, green: 0.56, blue: 0.16).opacity(0.40),
                    glow: Color(red: 1.0, green: 0.42, blue: 0.09).opacity(0.20),
                    isDark: true
                )
            }

            return StickyPalette(
                background: Color(red: 1.0, green: 0.58, blue: 0.24),
                primaryText: Color(red: 0.19, green: 0.08, blue: 0.02),
                secondaryText: Color(red: 0.42, green: 0.18, blue: 0.03).opacity(0.82),
                accent: Color(red: 0.74, green: 0.20, blue: 0.03),
                border: Color(red: 0.95, green: 0.33, blue: 0.05).opacity(0.64),
                glow: Color(red: 1.0, green: 0.37, blue: 0.06).opacity(0.22),
                isDark: false
            )
        }

        if status == .watching && urgency == .urgent {
            if interfaceIsDark {
                return StickyPalette(
                    background: Color(red: 0.28, green: 0.23, blue: 0.085),
                    primaryText: Color(red: 1.0, green: 0.95, blue: 0.80),
                    secondaryText: Color(red: 0.96, green: 0.80, blue: 0.42).opacity(0.76),
                    accent: Color(red: 0.98, green: 0.77, blue: 0.25),
                    border: Color(red: 1.0, green: 0.74, blue: 0.22).opacity(0.30),
                    glow: Color(red: 0.95, green: 0.64, blue: 0.12).opacity(0.12),
                    isDark: true
                )
            }

            return StickyPalette(
                background: Color(red: 1.0, green: 0.86, blue: 0.38),
                primaryText: Color(red: 0.16, green: 0.12, blue: 0.03),
                secondaryText: Color(red: 0.42, green: 0.30, blue: 0.06).opacity(0.82),
                accent: Color(red: 0.70, green: 0.42, blue: 0.04),
                border: Color(red: 0.92, green: 0.58, blue: 0.08).opacity(0.44),
                glow: Color(red: 0.90, green: 0.62, blue: 0.08).opacity(0.12),
                isDark: false
            )
        }

        switch urgency {
        case .urgent:
            if interfaceIsDark {
                return StickyPalette(
                    background: Color(red: 0.23, green: 0.20, blue: 0.095),
                    primaryText: Color(red: 1.0, green: 0.96, blue: 0.84),
                    secondaryText: Color(red: 0.90, green: 0.76, blue: 0.45).opacity(0.78),
                    accent: Color(red: 0.96, green: 0.70, blue: 0.22),
                    border: Color(red: 0.95, green: 0.64, blue: 0.18).opacity(0.24),
                    glow: Color(red: 0.86, green: 0.58, blue: 0.14).opacity(0.10),
                    isDark: true
                )
            }

            return StickyPalette(
                background: Color(red: 1.0, green: 0.88, blue: 0.52),
                primaryText: Color(red: 0.14, green: 0.10, blue: 0.03),
                secondaryText: Color(red: 0.36, green: 0.25, blue: 0.06).opacity(0.82),
                accent: Color(red: 0.62, green: 0.35, blue: 0.04),
                border: Color(red: 0.86, green: 0.56, blue: 0.09).opacity(0.30),
                glow: Color(red: 0.85, green: 0.52, blue: 0.08).opacity(0.08),
                isDark: false
            )
        case .neutral:
            if interfaceIsDark {
                return StickyPalette(
                    background: Color(red: 0.080, green: 0.145, blue: 0.220),
                    primaryText: Color(red: 0.88, green: 0.94, blue: 1.0),
                    secondaryText: Color(red: 0.68, green: 0.82, blue: 1.0).opacity(0.74),
                    accent: Color(red: 0.42, green: 0.69, blue: 1.0),
                    border: Color(red: 0.33, green: 0.58, blue: 0.90).opacity(0.28),
                    glow: Color(red: 0.20, green: 0.47, blue: 0.86).opacity(0.12),
                    isDark: true
                )
            }

            return StickyPalette(
                background: Color(red: 0.74, green: 0.88, blue: 1.0),
                primaryText: Color(red: 0.05, green: 0.11, blue: 0.20),
                secondaryText: Color(red: 0.12, green: 0.26, blue: 0.44).opacity(0.82),
                accent: Color(red: 0.09, green: 0.31, blue: 0.56),
                border: Color(red: 0.17, green: 0.48, blue: 0.78).opacity(0.38),
                glow: Color(red: 0.15, green: 0.43, blue: 0.75).opacity(0.10),
                isDark: false
            )
        case .relaxed:
            if interfaceIsDark {
                return StickyPalette(
                    background: Color(red: 0.090, green: 0.195, blue: 0.130),
                    primaryText: Color(red: 0.88, green: 1.0, blue: 0.90),
                    secondaryText: Color(red: 0.66, green: 0.88, blue: 0.68).opacity(0.74),
                    accent: Color(red: 0.42, green: 0.86, blue: 0.48),
                    border: Color(red: 0.35, green: 0.72, blue: 0.40).opacity(0.24),
                    glow: Color(red: 0.28, green: 0.70, blue: 0.36).opacity(0.11),
                    isDark: true
                )
            }

            return StickyPalette(
                background: Color(red: 0.72, green: 0.94, blue: 0.53),
                primaryText: Color(red: 0.08, green: 0.14, blue: 0.06),
                secondaryText: Color(red: 0.13, green: 0.35, blue: 0.08).opacity(0.82),
                accent: Color(red: 0.05, green: 0.44, blue: 0.08),
                border: Color(red: 0.25, green: 0.60, blue: 0.16).opacity(0.30),
                glow: Color(red: 0.28, green: 0.60, blue: 0.12).opacity(0.08),
                isDark: false
            )
        }
    }
}
