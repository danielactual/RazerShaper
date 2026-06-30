import ApplicationServices
import Foundation

public struct CGEventProbeEvent: CustomStringConvertible {
    public let type: CGEventType
    public let buttonNumber: Int64?
    public let keyCode: Int64?
    public let scrollDeltaY: Int64?
    public let scrollDeltaX: Int64?
    public let flags: UInt64

    public var description: String {
        [
            "type=\(typeName)",
            buttonNumber.map { "button=\($0)" },
            keyCode.map { "keyCode=\($0)" },
            scrollDeltaY.map { "scrollY=\($0)" },
            scrollDeltaX.map { "scrollX=\($0)" },
            "flags=0x" + String(flags, radix: 16, uppercase: true)
        ].compactMap { $0 }.joined(separator: " ")
    }

    public var typeName: String {
        switch type {
        case .leftMouseDown:
            return "leftMouseDown"
        case .leftMouseUp:
            return "leftMouseUp"
        case .rightMouseDown:
            return "rightMouseDown"
        case .rightMouseUp:
            return "rightMouseUp"
        case .otherMouseDown:
            return "otherMouseDown"
        case .otherMouseUp:
            return "otherMouseUp"
        case .scrollWheel:
            return "scrollWheel"
        case .keyDown:
            return "keyDown"
        case .keyUp:
            return "keyUp"
        case .flagsChanged:
            return "flagsChanged"
        case .tapDisabledByTimeout:
            return "tapDisabledByTimeout"
        case .tapDisabledByUserInput:
            return "tapDisabledByUserInput"
        default:
            return "cgEvent(\(type.rawValue))"
        }
    }
}

public final class CGEventProbeLogger {
    private let onEvent: (CGEventProbeEvent) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init(onEvent: @escaping (CGEventProbeEvent) -> Void) {
        self.onEvent = onEvent
    }

    deinit {
        stop()
    }

    public func start() throws {
        guard eventTap == nil else {
            return
        }

        let mask = [
            CGEventType.leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .scrollWheel,
            .keyDown,
            .keyUp,
            .flagsChanged
        ].reduce(CGEventMask(0)) { partial, type in
            partial | (1 << CGEventMask(type.rawValue))
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: cgEventProbeCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw CGEventProbeError.tapCreationFailed
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            throw CGEventProbeError.runLoopSourceCreationFailed
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
        eventTap = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout, let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }

        let probeEvent = CGEventProbeEvent(
            type: type,
            buttonNumber: mouseButtonNumber(for: type, event: event),
            keyCode: keyboardKeyCode(for: type, event: event),
            scrollDeltaY: type == .scrollWheel ? event.getIntegerValueField(.scrollWheelEventDeltaAxis1) : nil,
            scrollDeltaX: type == .scrollWheel ? event.getIntegerValueField(.scrollWheelEventDeltaAxis2) : nil,
            flags: event.flags.rawValue
        )
        onEvent(probeEvent)
    }

    private func mouseButtonNumber(for type: CGEventType, event: CGEvent) -> Int64? {
        switch type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp:
            return event.getIntegerValueField(.mouseEventButtonNumber)
        default:
            return nil
        }
    }

    private func keyboardKeyCode(for type: CGEventType, event: CGEvent) -> Int64? {
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            return event.getIntegerValueField(.keyboardEventKeycode)
        default:
            return nil
        }
    }
}

private let cgEventProbeCallback: CGEventTapCallBack = { _, type, event, userInfo in
    if let userInfo {
        let logger = Unmanaged<CGEventProbeLogger>.fromOpaque(userInfo).takeUnretainedValue()
        logger.handle(type: type, event: event)
    }
    return Unmanaged.passUnretained(event)
}

public enum CGEventProbeError: Error, CustomStringConvertible {
    case tapCreationFailed
    case runLoopSourceCreationFailed

    public var description: String {
        switch self {
        case .tapCreationFailed:
            return "CGEvent tap creation failed. Grant Input Monitoring permission to the built probe executable, then try again."
        case .runLoopSourceCreationFailed:
            return "CGEvent tap run loop source creation failed."
        }
    }
}
