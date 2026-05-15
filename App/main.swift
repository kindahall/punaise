import AppKit

#if DEBUG
if CommandLine.arguments.contains("--self-test") {
    Task { @MainActor in
        exit(PunaiseSelfTests.run())
    }
    dispatchMain()
}
#endif

let postitApp = NSApplication.shared
let postitDelegate = MainActor.assumeIsolated {
    AppDelegate()
}

postitApp.delegate = postitDelegate
postitApp.run()
