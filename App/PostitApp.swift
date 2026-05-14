import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var store = ReminderStore()
    private let desktopController = DesktopStickyController()
    private let hotKeyController = GlobalHotKeyController()
    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    private var urgencyNowWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PunaisePreferences.registerDefaults()
        NSApp.setActivationPolicy(.regular)
        configureApplicationIcon()
        configureMenus()
        configureStatusItem()
        configureGlobalShortcut()
        ReminderNotificationScheduler.requestAuthorization(for: store.reminders)
        desktopController.attach(store: store)
        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)

        if !UserDefaults.standard.bool(forKey: PunaisePreferenceKey.hasCompletedOnboarding) {
            showOnboardingWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    @objc private func createReminderMenuItem() {
        createReminder()
    }

    @objc private func showMainWindowMenuItem() {
        showMainWindow()
    }

    @objc private func showPreferencesMenuItem() {
        showPreferencesWindow()
    }

    @objc private func showOnboardingMenuItem() {
        showOnboardingWindow()
    }

    @objc private func openCalendarImportMenuItem() {
        showMainWindow()
        NotificationCenter.default.post(name: .postitOpenCalendarImport, object: nil)
    }

    @objc private func openRemindersImportMenuItem() {
        showMainWindow()
        NotificationCenter.default.post(name: .postitOpenRemindersImport, object: nil)
    }

    @objc private func showUrgencyNowMenuItem() {
        showUrgencyNowWindow()
    }

    @objc private func requestNotificationsMenuItem() {
        requestNotifications()
    }

    @objc private func cleanDesktopMenuItem() {
        desktopController.cleanDesktop(in: store)
    }

    @objc private func toggleFocusMenuItem() {
        let key = PunaisePreferenceKey.focusUrgenciesOnDesktop
        let nextValue = !UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(nextValue, forKey: key)
        desktopController.focusesUrgenciesOnly = nextValue
    }

    private func createReminder() {
        let reminder = store.createReminder()
        desktopController.pin(reminder.id, in: store)
        showMainWindow(selecting: reminder.id)
    }

    private func createFirstLaunchPunaise() {
        let reminder = store.createFirstLaunchPunaise()
        desktopController.pin(reminder.id, in: store)
        showMainWindow(selecting: reminder.id)
    }

    private func requestNotifications() {
        ReminderNotificationScheduler.requestAuthorization(for: store.reminders)
    }

    private func configureGlobalShortcut() {
        hotKeyController.onCreatePunaise = { [weak self] in
            self?.createReminder()
        }
        hotKeyController.register()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Punaise")
        item.button?.imagePosition = .imageLeading
        item.button?.title = " Punaise"

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Nouvelle Punaise",
                action: #selector(createReminderMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Afficher Punaise",
                action: #selector(showMainWindowMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Google Agenda",
                action: #selector(openCalendarImportMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Apple Reminders",
                action: #selector(openRemindersImportMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Bureau propre",
                action: #selector(cleanDesktopMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Ce qui presse",
                action: #selector(showUrgencyNowMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Mode Focus",
                action: #selector(toggleFocusMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Préférences",
                action: #selector(showPreferencesMenuItem),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quitter Punaise",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: ""
            )
        )

        item.menu = menu
        statusItem = item
    }

    private func showMainWindow(selecting reminderID: Reminder.ID? = nil) {
        if mainWindow == nil {
            let contentView = ContentView(
                store: store,
                desktopController: desktopController,
                initialSelection: reminderID
            )
            .frame(minWidth: 980, minHeight: 680)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1080, height: 720),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Punaise"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 980, height: 680)
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            mainWindow = window
        }

        if let reminderID {
            NotificationCenter.default.post(name: .postitSelectReminder, object: reminderID)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    private func showOnboardingWindow() {
        if onboardingWindow == nil {
            let view = OnboardingView(
                onRequestNotifications: { [weak self] in
                    self?.requestNotifications()
                },
                onCreateFirstPunaise: { [weak self] in
                    self?.createFirstLaunchPunaise()
                },
                onFinish: { [weak self] in
                    UserDefaults.standard.set(true, forKey: PunaisePreferenceKey.hasCompletedOnboarding)
                    self?.onboardingWindow?.close()
                    self?.onboardingWindow = nil
                    self?.showMainWindow()
                }
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Bienvenue dans Punaise"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: view)
            window.center()
            onboardingWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    private func showPreferencesWindow() {
        if preferencesWindow == nil {
            let view = PreferencesView(
                store: store,
                desktopController: desktopController,
                onShowOnboarding: { [weak self] in
                    self?.showOnboardingWindow()
                },
                onRequestNotifications: { [weak self] in
                    self?.requestNotifications()
                }
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Préférences"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: view)
            window.center()
            preferencesWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    private func showUrgencyNowWindow() {
        if urgencyNowWindow == nil {
            let view = UrgencyNowWindow(
                store: store,
                onOpen: { [weak self] id in
                    self?.store.markOpened(id)
                    self?.showMainWindow(selecting: id)
                }
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 390, height: 360),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Ce qui presse"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.contentView = NSHostingView(rootView: view)
            window.center()
            urgencyNowWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        urgencyNowWindow?.makeKeyAndOrderFront(nil)
    }

    private func configureMenus() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            NSMenuItem(
                title: "À propos de Punaise",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            )
        )
        appMenu.addItem(
            NSMenuItem(
                title: "Préférences…",
                action: #selector(showPreferencesMenuItem),
                keyEquivalent: ","
            )
        )
        appMenu.addItem(
            NSMenuItem(
                title: "Revoir l’introduction",
                action: #selector(showOnboardingMenuItem),
                keyEquivalent: ""
            )
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quitter Punaise",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Fichier")
        let newPunaiseItem = NSMenuItem(
            title: "Nouvelle Punaise",
            action: #selector(createReminderMenuItem),
            keyEquivalent: "n"
        )
        fileMenu.addItem(newPunaiseItem)

        let quickPunaiseItem = NSMenuItem(
            title: "Nouvelle Punaise rapide",
            action: #selector(createReminderMenuItem),
            keyEquivalent: "p"
        )
        quickPunaiseItem.keyEquivalentModifierMask = [.control, .option]
        fileMenu.addItem(quickPunaiseItem)

        fileMenu.addItem(.separator())
        fileMenu.addItem(
            NSMenuItem(
                title: "Importer Google Agenda…",
                action: #selector(openCalendarImportMenuItem),
                keyEquivalent: "g"
            )
        )
        fileMenu.addItem(
            NSMenuItem(
                title: "Importer Apple Reminders…",
                action: #selector(openRemindersImportMenuItem),
                keyEquivalent: "r"
            )
        )
        fileMenu.addItem(.separator())
        fileMenu.addItem(
            NSMenuItem(
                title: "Bureau propre",
                action: #selector(cleanDesktopMenuItem),
                keyEquivalent: "b"
            )
        )
        fileMenu.addItem(
            NSMenuItem(
                title: "Ce qui presse",
                action: #selector(showUrgencyNowMenuItem),
                keyEquivalent: ""
            )
        )
        fileMenu.addItem(
            NSMenuItem(
                title: "Mode Focus",
                action: #selector(toggleFocusMenuItem),
                keyEquivalent: "u"
            )
        )
        fileMenu.addItem(
            NSMenuItem(
                title: "Autoriser les notifications",
                action: #selector(requestNotificationsMenuItem),
                keyEquivalent: ""
            )
        )
        fileMenu.addItem(.separator())
        fileMenu.addItem(
            NSMenuItem(
                title: "Afficher Punaise",
                action: #selector(showMainWindowMenuItem),
                keyEquivalent: "0"
            )
        )
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Fenêtre")
        windowMenu.addItem(
            NSMenuItem(
                title: "Afficher Punaise",
                action: #selector(showMainWindowMenuItem),
                keyEquivalent: "1"
            )
        )
        windowMenu.addItem(
            NSMenuItem(
                title: "Ce qui presse",
                action: #selector(showUrgencyNowMenuItem),
                keyEquivalent: "2"
            )
        )
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    private func configureApplicationIcon() {
        let iconURLs = [
            Bundle.main.url(forResource: "Punaise", withExtension: "icns"),
            Bundle.main.url(forResource: "PunaiseIcon1024", withExtension: "png"),
            Bundle.module.url(forResource: "PunaiseIcon1024", withExtension: "png"),
            Bundle.module.url(forResource: "PunaiseIcon1024", withExtension: "png", subdirectory: "Resources")
        ]

        for url in iconURLs.compactMap({ $0 }) {
            if let image = NSImage(contentsOf: url) {
                NSApp.applicationIconImage = image
                return
            }
        }
    }
}
