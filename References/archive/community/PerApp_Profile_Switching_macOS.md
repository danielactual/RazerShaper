# Per-Application Profile Switching on macOS
## Reference for Razer Ouroboros Custom Driver

### The Core API: NSWorkspace.frontmostApplication
Available since macOS 10.7. KVO-compliant (can be observed for changes).

```swift
// Observe active app changes
NSWorkspace.shared.addObserver(self,
    forKeyPath: "frontmostApplication",
    options: [.new],
    context: nil)

// In observeValue:
override func observeValue(forKeyPath keyPath: String?, ...) {
    if keyPath == "frontmostApplication" {
        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = app?.bundleIdentifier ?? "unknown"
        // Look up profile for bundleID and apply
        applyProfile(for: bundleID)
    }
}
```

### Alternative: NSWorkspace Notification
```swift
NSWorkspace.shared.notificationCenter.addObserver(
    self,
    selector: #selector(activeAppChanged(_:)),
    name: NSWorkspace.didActivateApplicationNotification,
    object: nil)

@objc func activeAppChanged(_ note: Notification) {
    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    let bundleID = app?.bundleIdentifier ?? ""
    applyProfile(for: bundleID)
}
```

### Key Properties of NSRunningApplication
- `bundleIdentifier`: e.g., "com.apple.Safari" — use this as profile key
- `localizedName`: Human-readable name for display in UI
- `bundleURL`: Path to .app bundle

### Permissions Required
- Per-app switching via NSWorkspace requires NO special permissions.
- The CGEventTap for intercepting extra buttons requires:
  - **Input Monitoring** (System Settings → Privacy & Security → Input Monitoring)
  - Request at runtime: `IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)`
  - Check first: `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)`
- Sending feature reports to the mouse via IOHIDManager requires:
  - **Input Monitoring** (same permission as above)
  - App must NOT be sandboxed (App Sandbox breaks IOHIDDeviceOpen silently)

### Profile Storage
Store profiles as a dictionary keyed by bundle identifier in UserDefaults or a JSON file:
```json
{
  "com.apple.Safari": { "button6": "back", "button7": "forward" },
  "com.adobe.Photoshop": { "button6": "undo", "button7": "redo" },
  "default": { "button6": "button4", "button7": "button5" }
}
```

### macOS Permissions Checklist for the App
1. `LSUIElement = YES` in Info.plist (menu bar only, no Dock icon)
2. App Sandbox: DISABLED
3. Input Monitoring: requested at first launch via `IOHIDRequestAccess`
4. Accessibility: NOT required for CGEventTap with `kCGEventTapOptionDefault`
   (but IS required if using AXUIElement APIs)
