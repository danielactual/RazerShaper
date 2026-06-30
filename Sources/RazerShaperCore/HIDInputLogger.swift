import Foundation
import IOKit
import IOKit.hid

public struct HIDInputEvent: CustomStringConvertible {
    public let device: HIDDeviceInfo
    public let timestamp: UInt64
    public let usagePage: Int
    public let usage: Int
    public let elementCookie: Int
    public let integerValue: Int
    public let logicalMin: Int
    public let logicalMax: Int

    public var isGenericDesktopMotion: Bool {
        usagePage == 0x01 && [0x30, 0x31, 0x38].contains(usage)
    }

    public var isVendorDefined: Bool {
        usagePage >= 0xFF00
    }

    public var isButtonLike: Bool {
        usagePage == 0x09
    }

    public var isKeyboardLike: Bool {
        usagePage == 0x07
    }

    public var isConsumerControlLike: Bool {
        usagePage == 0x0C
    }

    public var isDefaultProbeEvent: Bool {
        isButtonLike || isKeyboardLike || isConsumerControlLike
    }

    public var description: String {
        [
            "value=\(integerValue)",
            "usagePage=\(hex(usagePage, width: 2))",
            "usage=\(hex(usage, width: 2))",
            "cookie=\(elementCookie)",
            "logical=\(logicalMin)...\(logicalMax)",
            "device={\(device.description)}"
        ].joined(separator: " ")
    }
}

public final class HIDInputLogger {
    private let manager: IOHIDManager
    private let onEvent: (HIDInputEvent) -> Void
    private var isStarted = false

    public init(filter: HIDDeviceFilter = .razer, onEvent: @escaping (HIDInputEvent) -> Void) {
        self.manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.onEvent = onEvent

        IOHIDManagerSetDeviceMatching(manager, filter.matchingDictionary)
        IOHIDManagerRegisterInputValueCallback(manager, hidInputValueCallback, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        stop()
    }

    public func start() throws {
        guard !isStarted else {
            return
        }

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            throw HIDError(operation: "IOHIDManagerOpen", code: result)
        }
        isStarted = true
    }

    public func stop() {
        guard isStarted else {
            return
        }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        isStarted = false
    }

    fileprivate func handle(value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let device = IOHIDElementGetDevice(element)
        let event = HIDInputEvent(
            device: HIDDeviceInfo(device: device),
            timestamp: UInt64(IOHIDValueGetTimeStamp(value)),
            usagePage: Int(IOHIDElementGetUsagePage(element)),
            usage: Int(IOHIDElementGetUsage(element)),
            elementCookie: Int(IOHIDElementGetCookie(element)),
            integerValue: IOHIDValueGetIntegerValue(value),
            logicalMin: Int(IOHIDElementGetLogicalMin(element)),
            logicalMax: Int(IOHIDElementGetLogicalMax(element))
        )
        onEvent(event)
    }
}

private let hidInputValueCallback: IOHIDValueCallback = { context, result, _, value in
    guard result == kIOReturnSuccess, let context else {
        return
    }
    let logger = Unmanaged<HIDInputLogger>.fromOpaque(context).takeUnretainedValue()
    logger.handle(value: value)
}
