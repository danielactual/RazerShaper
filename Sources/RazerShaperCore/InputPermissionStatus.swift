import ApplicationServices
import Foundation
import IOKit.hidsystem

public struct InputPermissionStatus: CustomStringConvertible {
    public let listenEventAccess: IOHIDAccessType
    public let postEventAccess: IOHIDAccessType
    public let accessibilityTrusted: Bool

    public static func current() -> InputPermissionStatus {
        InputPermissionStatus(
            listenEventAccess: IOHIDCheckAccess(kIOHIDRequestTypeListenEvent),
            postEventAccess: IOHIDCheckAccess(kIOHIDRequestTypePostEvent),
            accessibilityTrusted: AXIsProcessTrusted()
        )
    }

    @discardableResult
    public static func requestListenEventAccess() -> Bool {
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    public var canListenToHIDEvents: Bool {
        listenEventAccess == kIOHIDAccessTypeGranted
    }

    public var canUseAccessibilityEvents: Bool {
        accessibilityTrusted
    }

    public var description: String {
        [
            "Input Monitoring listen access: \(Self.describe(access: listenEventAccess))",
            "Input Monitoring post access: \(Self.describe(access: postEventAccess))",
            "Accessibility trusted: \(accessibilityTrusted ? "granted" : "not granted")"
        ].joined(separator: "\n")
    }

    private static func describe(access: IOHIDAccessType) -> String {
        switch access {
        case kIOHIDAccessTypeGranted:
            return "granted"
        case kIOHIDAccessTypeDenied:
            return "denied"
        case kIOHIDAccessTypeUnknown:
            return "unknown"
        default:
            return "unknown(\(access.rawValue))"
        }
    }
}
