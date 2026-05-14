import AppKit

let postitApp = NSApplication.shared
let postitDelegate = MainActor.assumeIsolated {
    AppDelegate()
}

postitApp.delegate = postitDelegate
postitApp.run()
