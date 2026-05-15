#if DEBUG
import Foundation

@MainActor
enum PunaiseSelfTests {
    private static let signedAnnualKey = "PUNAISE1.eyJ2IjoxLCJwcm9kdWN0IjoicHVuYWlzZV9wcm8iLCJwbGFuIjoiYW5udWFsIiwiaXNzdWVkQXQiOiIyMDI2LTA1LTE1VDAwOjAwOjAwLjAwMFoiLCJlbWFpbEhhc2giOiJjZjllNjE2M2I3M2Q1OGU2N2Q1MWMxYjdkMTc5M2RkZDdjNDc5NmNiZTY3MGU4YzkzMmVmYmUzMTUzZWE1NjY0Iiwic2Vzc2lvbklkIjoiY3NfdGVzdF9wdW5haXNlX2xpY2Vuc2UiLCJyZXF1ZXN0SWQiOiJ0ZXN0LXJlcXVlc3QifQ.MEUCIFlsLWRBMbk6bdqvWheDfaZ-6wnvxNm4OYGhcKzwikTxAiEA3afRmOMCtS3ysxxJpyPhAT0F4DAA6qx1JG8DesGeDeI"

    static func run() -> Int32 {
        var failures: [String] = []

        check(PunaiseLicense.isValid(signedAnnualKey), "accepts server-signed license", failures: &failures)
        check(!PunaiseLicense.isValid(tamperedSignedKey()), "rejects tampered signed license", failures: &failures)
        check(!PunaiseLicense.isValid("PUNAISE-ABCD-2345-WXYZ"), "rejects legacy checksum-only license", failures: &failures)
        check(PunaiseLicense.isValid(" \n\(signedAnnualKey)\t "), "normalizes signed license whitespace", failures: &failures)

        runReminderStoreTests(failures: &failures)

        if failures.isEmpty {
            print("Punaise self-tests passed.")
            return 0
        }

        for failure in failures {
            fputs("Punaise self-test failed: \(failure)\n", stderr)
        }
        return 1
    }

    private static func runReminderStoreTests(failures: inout [String]) {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("PunaiseSelfTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let storageURL = folder.appendingPathComponent("punaises.json")
        let store = ReminderStore(storageURL: storageURL)
        check(store.reminders.isEmpty, "missing storage starts empty", failures: &failures)
        check(store.activeReminderCount == 0, "missing storage has zero active reminders", failures: &failures)

        let reminder = store.createFirstLaunchPunaise()
        check(store.reminders.map(\.id) == [reminder.id], "first launch reminder is explicit", failures: &failures)
        check(store.activeReminderCount == 1, "first launch reminder counts as one active reminder", failures: &failures)

        store.resetToExamples()
        check(store.reminders.isEmpty, "reset leaves no example reminders", failures: &failures)
        check(store.activeReminderCount == 0, "reset leaves zero active examples", failures: &failures)
    }

    private static func tamperedSignedKey() -> String {
        signedAnnualKey.replacingOccurrences(of: "YW5udWFs", with: "bW9udGhseQ")
    }

    private static func check(_ condition: Bool, _ name: String, failures: inout [String]) {
        if !condition {
            failures.append(name)
        }
    }
}
#endif
