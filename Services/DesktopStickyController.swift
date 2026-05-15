import AppKit
import Combine
import SwiftUI

@MainActor
final class DesktopStickyController: ObservableObject {
    private enum StickyWindowMetrics {
        static let cardSize = CGSize(width: 286, height: 184)
        static let windowPadding: CGFloat = 16

        static var windowSize: CGSize {
            CGSize(
                width: cardSize.width + windowPadding * 2,
                height: cardSize.height + windowPadding * 2
            )
        }
    }

    @Published var focusesUrgenciesOnly = false {
        didSet { sync(store?.reminders ?? []) }
    }

    @Published var usesAdaptiveDesk = true {
        didSet { sync(store?.reminders ?? []) }
    }

    var onOpenReminder: ((Reminder.ID) -> Void)?

    private weak var store: ReminderStore?
    private var cancellable: AnyCancellable?
    private var clockCancellable: AnyCancellable?
    private var windows: [Reminder.ID: NSWindow] = [:]
    private var delegates: [Reminder.ID: StickyWindowDelegate] = [:]
    private var programmaticMoves = Set<Reminder.ID>()
    private var appearingWindows = Set<Reminder.ID>()
    private var manualDragIDs = Set<Reminder.ID>()
    private var shouldSkipNextAutomaticClean = false

    func attach(store: ReminderStore) {
        self.store = store

        if cancellable == nil {
            cancellable = store.$reminders.sink { [weak self] reminders in
                self?.sync(reminders)
            }
        }

        if clockCancellable == nil {
            clockCancellable = Timer.publish(every: 45, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.sync(self?.store?.reminders ?? [])
                }
        }

        sync(store.reminders)
    }

    func pin(_ id: Reminder.ID, in store: ReminderStore) {
        store.setPinned(id, isPinned: true, position: randomPosition())
    }

    func randomizePosition(for id: Reminder.ID, in store: ReminderStore) {
        let position = randomPosition()
        store.setDesktopPosition(id, position: position)

        guard let window = windows[id] else { return }
        var frame = window.frame
        frame.origin = CGPoint(x: position.x, y: position.y)
        setFrame(frame, for: id, window: window, animate: true)
    }

    func cleanDesktop(in store: ReminderStore) {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        let layout = desktopLayout(for: store.reminders)

        for item in layout {
            let position = managedPosition(zone: item.zone, index: item.index, visibleFrame: visibleFrame)
            store.setDesktopPosition(item.reminder.id, position: position)

            if let window = windows[item.reminder.id] {
                var frame = window.frame
                frame.origin = CGPoint(x: position.x, y: position.y)
                setFrame(frame, for: item.reminder.id, window: window, animate: true)
            }
        }
    }

    func consumeAutomaticCleanSkipAfterManualMove() -> Bool {
        guard shouldSkipNextAutomaticClean else { return false }
        shouldSkipNextAutomaticClean = false
        return true
    }

    private func sync(_ reminders: [Reminder]) {
        let visibleReminders = reminders.filter { reminder in
            guard reminder.isPinned && !reminder.isArchived else { return false }
            guard focusesUrgenciesOnly else { return true }
            return reminder.status().isUrgentNow
        }
        let visibleIDs = Set(visibleReminders.map(\.id))

        for id in windows.keys where !visibleIDs.contains(id) {
            windows[id]?.close()
            windows[id] = nil
            delegates[id] = nil
        }

        for reminder in visibleReminders {
            var visibleReminder = reminder

            if visibleReminder.desktopPosition == nil {
                let position = randomPosition()
                visibleReminder.desktopPosition = position

                Task { @MainActor [weak self] in
                    self?.store?.setDesktopPosition(reminder.id, position: position)
                }
            }

            if let window = windows[visibleReminder.id] {
                update(window: window, with: visibleReminder)
            } else {
                createWindow(for: visibleReminder)
            }
        }
    }

    private func createWindow(for reminder: Reminder) {
        let size = StickyWindowMetrics.windowSize
        let position = reminder.desktopPosition ?? randomPosition()
        let frame = NSRect(
            x: position.x,
            y: position.y,
            width: size.width,
            height: size.height
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.title = reminder.displayTitle
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.alphaValue = 0
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true

        let delegate = StickyWindowDelegate(id: reminder.id) { [weak self] id, frame in
            guard let self,
                  !self.programmaticMoves.contains(id),
                  !self.manualDragIDs.contains(id)
            else { return }

            let position = DesktopPosition(x: frame.origin.x, y: frame.origin.y)
            if let current = self.store?.reminder(id: id)?.desktopPosition,
               self.distance(from: CGPoint(x: current.x, y: current.y), to: frame.origin) <= 2 {
                return
            }

            self.store?.setDesktopPosition(id, position: position)
        }

        window.delegate = delegate
        delegates[reminder.id] = delegate
        windows[reminder.id] = window
        appearingWindows.insert(reminder.id)

        update(window: window, with: reminder, animateEntrance: true)
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            window.animator().alphaValue = 1
        }

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            self?.appearingWindows.remove(reminder.id)
        }
    }

    private func update(window: NSWindow, with reminder: Reminder, animateEntrance: Bool = false) {
        window.title = reminder.displayTitle
        let status = reminder.status()
        let stage = reminder.antiForgetStage()
        window.level = windowLevel(for: status, stage: stage)

        if let position = reminder.desktopPosition {
            var frame = window.frame
            let targetOrigin = CGPoint(x: position.x, y: position.y)
            if distance(from: frame.origin, to: targetOrigin) > 2 {
                frame.origin = targetOrigin
                setFrame(frame, for: reminder.id, window: window)
            }
        }

        let shouldAnimateEntrance = animateEntrance || appearingWindows.contains(reminder.id)
        let rootView = FloatingStickyView(
            reminder: reminder,
            appearsAnimated: shouldAnimateEntrance,
            onOpen: { [weak self] in
                self?.activateApp()
                self?.onOpenReminder?(reminder.id)
            },
            onUnpin: { [weak self] in
                self?.store?.setPinned(reminder.id, isPinned: false)
            }
        )

        let onDragEnded: (NSRect) -> Void = { [weak self] frame in
            self?.manualDragIDs.remove(reminder.id)
            self?.shouldSkipNextAutomaticClean = true
            self?.store?.setDesktopPosition(
                reminder.id,
                position: DesktopPosition(x: frame.origin.x, y: frame.origin.y)
            )
        }

        let onDragBegan: () -> Void = { [weak self] in
            self?.manualDragIDs.insert(reminder.id)
            UserDefaults.standard.set(false, forKey: PunaisePreferenceKey.autoCleanDesktop)
        }

        if let hostingView = window.contentView as? DraggableStickyHostingView<FloatingStickyView> {
            hostingView.rootView = rootView
            hostingView.onDragBegan = onDragBegan
            hostingView.onDragEnded = onDragEnded
        } else {
            window.contentView = DraggableStickyHostingView(
                rootView: rootView,
                onDragBegan: onDragBegan,
                onDragEnded: onDragEnded
            )
        }

        if usesAdaptiveDesk && stage.shouldReturnToFront {
            window.orderFrontRegardless()
        }
    }

    private func activateApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first(where: { $0.styleMask.contains(.titled) && $0.title == "Punaise" })
            .map { $0.makeKeyAndOrderFront(nil) }
    }

    private func randomPosition() -> DesktopPosition {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        let width = StickyWindowMetrics.windowSize.width
        let height = StickyWindowMetrics.windowSize.height
        let minX = visibleFrame.minX + 28
        let maxX = max(minX, visibleFrame.maxX - width - 28)
        let minY = visibleFrame.minY + 48
        let maxY = max(minY, visibleFrame.maxY - height - 48)

        return DesktopPosition(
            x: Double(CGFloat.random(in: minX...maxX)),
            y: Double(CGFloat.random(in: minY...maxY))
        )
    }

    private func desktopLayout(for reminders: [Reminder]) -> [(reminder: Reminder, zone: DesktopLayoutZone, index: Int)] {
        let pinned = reminders
            .filter { $0.isPinned && !$0.isArchived }
            .sorted { first, second in
                if first.pressureScore() != second.pressureScore() {
                    return first.pressureScore() > second.pressureScore()
                }

                return first.deadline < second.deadline
            }

        let overdue = pinned.filter { $0.status() == .overdue }
        let urgent = pinned.filter { [.critical, .pressing].contains($0.status()) }
        let watching = pinned.filter { $0.status() == .watching }
        let calm = pinned.filter { $0.status() == .calm }

        return overdue.enumerated().map { (reminder: $0.element, zone: .black, index: $0.offset) }
            + urgent.enumerated().map { (reminder: $0.element, zone: .center, index: $0.offset) }
            + watching.enumerated().map { (reminder: $0.element, zone: .side, index: $0.offset) }
            + calm.enumerated().map { (reminder: $0.element, zone: .quiet, index: $0.offset) }
    }

    private func managedPosition(zone: DesktopLayoutZone, index: Int, visibleFrame: NSRect) -> DesktopPosition {
        let width = StickyWindowMetrics.windowSize.width
        let height = StickyWindowMetrics.windowSize.height
        let spacing: CGFloat = 16
        let row = index / zone.columns
        let column = index % zone.columns
        let xOffset = CGFloat(column) * (width + spacing)
        let yOffset = CGFloat(row) * (height + spacing)

        switch zone {
        case .black:
            return DesktopPosition(
                x: Double(visibleFrame.minX + 34 + xOffset),
                y: Double(max(visibleFrame.minY + 40, visibleFrame.maxY - height - 58 - yOffset))
            )
        case .center:
            let totalWidth = CGFloat(zone.columns) * width + CGFloat(zone.columns - 1) * spacing
            return DesktopPosition(
                x: Double(max(visibleFrame.minX + 34, visibleFrame.midX - totalWidth / 2 + xOffset)),
                y: Double(max(visibleFrame.minY + 40, visibleFrame.midY - height / 2 - yOffset))
            )
        case .side:
            return DesktopPosition(
                x: Double(max(visibleFrame.minX + 34, visibleFrame.maxX - width - 34 - xOffset)),
                y: Double(max(visibleFrame.minY + 40, visibleFrame.maxY - height - 58 - yOffset))
            )
        case .quiet:
            return DesktopPosition(
                x: Double(max(visibleFrame.minX + 34, visibleFrame.maxX - width - 34 - xOffset)),
                y: Double(visibleFrame.minY + 54 + yOffset)
            )
        }
    }

    private func windowLevel(for status: ReminderStatus, stage: AntiForgetStage) -> NSWindow.Level {
        guard usesAdaptiveDesk else { return .floating }

        if stage.shouldReturnToFront {
            return .statusBar
        }

        switch status {
        case .critical, .overdue:
            return .statusBar
        case .pressing:
            return .floating
        case .watching, .calm:
            return .floating
        }
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private func setFrame(_ frame: NSRect, for id: Reminder.ID, window: NSWindow, animate: Bool = false) {
        programmaticMoves.insert(id)
        window.setFrame(frame, display: true, animate: animate)

        Task { @MainActor [weak self] in
            self?.programmaticMoves.remove(id)
        }
    }
}

private enum DesktopLayoutZone {
    case black
    case center
    case side
    case quiet

    var columns: Int {
        switch self {
        case .center:
            return 2
        case .black, .side, .quiet:
            return 1
        }
    }
}

private final class StickyWindowDelegate: NSObject, NSWindowDelegate {
    private let id: Reminder.ID
    private let onMove: (Reminder.ID, NSRect) -> Void

    init(id: Reminder.ID, onMove: @escaping (Reminder.ID, NSRect) -> Void) {
        self.id = id
        self.onMove = onMove
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onMove(id, window.frame)
    }
}

private final class DraggableStickyHostingView<Content: View>: NSHostingView<Content> {
    var onDragBegan: (() -> Void)?
    var onDragEnded: ((NSRect) -> Void)?

    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?
    private var didDrag = false

    required init(rootView: Content) {
        super.init(rootView: rootView)
    }

    convenience init(
        rootView: Content,
        onDragBegan: (() -> Void)? = nil,
        onDragEnded: ((NSRect) -> Void)? = nil
    ) {
        self.init(rootView: rootView)
        self.onDragBegan = onDragBegan
        self.onDragEnded = onDragEnded
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var mouseDownCanMoveWindow: Bool {
        true
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartWindowOrigin = window?.frame.origin
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let window,
            let dragStartMouseLocation,
            let dragStartWindowOrigin
        else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let nextOrigin = NSPoint(
            x: dragStartWindowOrigin.x + currentMouseLocation.x - dragStartMouseLocation.x,
            y: dragStartWindowOrigin.y + currentMouseLocation.y - dragStartMouseLocation.y
        )

        if !didDrag {
            didDrag = true
            onDragBegan?()
        }
        window.setFrameOrigin(nextOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag, let window {
            onDragEnded?(window.frame)
        }

        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
        didDrag = false
        super.mouseUp(with: event)
    }
}
