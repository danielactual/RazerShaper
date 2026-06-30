import AppKit
import RazerShaperCore

@main
@MainActor
final class RazerShaperApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let deviceStatusItem = NSMenuItem(title: "Device: Checking...", action: nil, keyEquivalent: "")

    static func main() {
        let app = NSApplication.shared
        let delegate = RazerShaperApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "RS"
        statusItem.menu = buildMenu()
        self.statusItem = statusItem
        refreshDeviceStatus()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "RazerShaper", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        deviceStatusItem.isEnabled = false
        menu.addItem(deviceStatusItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh Device", action: #selector(refreshDeviceStatus), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit RazerShaper", action: #selector(quit), keyEquivalent: "q"))

        return menu
    }

    @objc private func refreshDeviceStatus() {
        do {
            let devices = try HIDDeviceEnumerator().devices(matching: .likelyOuroboros)
            let controlInterface = devices.first { $0.hasRazerFeatureReportSize }

            if let controlInterface {
                statusItem?.button?.title = "RS*"
                deviceStatusItem.title = "Device: \(controlInterface.product ?? "Razer mouse") on interface \(controlInterface.interfaceNumber.map(String.init) ?? "unknown")"
            } else if devices.isEmpty {
                statusItem?.button?.title = "RS"
                deviceStatusItem.title = "Device: Not connected"
            } else {
                statusItem?.button?.title = "RS"
                deviceStatusItem.title = "Device: Connected, control interface not found"
            }
        } catch {
            statusItem?.button?.title = "RS"
            deviceStatusItem.title = "Device: Error"
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
