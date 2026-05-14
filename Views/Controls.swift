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
                .buttonStyle(.plain)
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

    var body: some View {
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
        .foregroundStyle(Color(red: 0.08, green: 0.22, blue: 0.40))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Color(red: 0.08, green: 0.20, blue: 0.37)
                    .opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(red: 0.08, green: 0.20, blue: 0.37))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.black.opacity(configuration.isPressed ? 0.08 : 0.04),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.08))
            )
    }
}

struct IconButtonStyle: ButtonStyle {
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isActive ? .blue : .secondary)
            .background(
                (isActive ? Color.blue.opacity(0.13) : Color.black.opacity(0.04))
                    .opacity(configuration.isPressed ? 0.60 : 1),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isActive ? Color.blue.opacity(0.20) : Color.black.opacity(0.08))
            )
    }
}
