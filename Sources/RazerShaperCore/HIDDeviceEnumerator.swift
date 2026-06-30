import Foundation
import IOKit
import IOKit.hid

public struct HIDDeviceEnumerator {
    public init() {}

    public func devices(matching filter: HIDDeviceFilter = .razer) throws -> [HIDDeviceInfo] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, filter.matchingDictionary)

        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            throw HIDError(operation: "IOHIDManagerOpen", code: openResult)
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        guard let deviceSet = IOHIDManagerCopyDevices(manager) else {
            return []
        }

        return Self.devices(from: deviceSet)
            .map(HIDDeviceInfo.init(device:))
            .sorted { lhs, rhs in
                (lhs.product ?? "", lhs.productID ?? -1, lhs.primaryUsagePage ?? -1, lhs.primaryUsage ?? -1)
                    < (rhs.product ?? "", rhs.productID ?? -1, rhs.primaryUsagePage ?? -1, rhs.primaryUsage ?? -1)
            }
    }

    static func devices(from set: CFSet) -> [IOHIDDevice] {
        let count = CFSetGetCount(set)
        guard count > 0 else {
            return []
        }

        var rawValues = [UnsafeRawPointer?](repeating: nil, count: count)
        rawValues.withUnsafeMutableBufferPointer { buffer in
            CFSetGetValues(set, buffer.baseAddress)
        }

        return rawValues.compactMap { rawValue in
            guard let rawValue else {
                return nil
            }
            return Unmanaged<IOHIDDevice>.fromOpaque(rawValue).takeUnretainedValue()
        }
    }
}

public struct HIDError: Error, CustomStringConvertible {
    public let operation: String
    public let code: IOReturn

    public var description: String {
        "\(operation) failed with IOReturn \(formatIOReturn(code))"
    }
}

public func formatIOReturn(_ code: IOReturn) -> String {
    let unsigned = UInt32(bitPattern: code)
    return "0x" + String(unsigned, radix: 16, uppercase: true)
}
