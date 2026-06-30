import Foundation
import IOKit
import IOKit.hid

public struct HIDDeviceInfo: Equatable, CustomStringConvertible {
    public let registryEntryID: UInt64?
    public let vendorID: Int?
    public let productID: Int?
    public let product: String?
    public let manufacturer: String?
    public let serialNumber: String?
    public let primaryUsagePage: Int?
    public let primaryUsage: Int?
    public let maxInputReportSize: Int?
    public let maxOutputReportSize: Int?
    public let maxFeatureReportSize: Int?
    public let locationID: Int?
    public let interfaceNumber: Int?
    public let transport: String?

    public var isRazer: Bool {
        vendorID == RazerConstants.vendorID
    }

    public var isLikelyOuroboros: Bool {
        vendorID == RazerConstants.vendorID && productID == RazerConstants.likelyOuroborosProductID
    }

    public var hasRazerFeatureReportSize: Bool {
        maxFeatureReportSize == RazerConstants.reportLength
    }

    public var description: String {
        let flags = [
            isRazer ? "razer" : nil,
            isLikelyOuroboros ? "likely-ouroboros" : nil,
            hasRazerFeatureReportSize ? "feature90" : nil
        ].compactMap { $0 }.joined(separator: ",")

        return [
            "product=\(product ?? "unknown")",
            "manufacturer=\(manufacturer ?? "unknown")",
            "vid=\(hex(vendorID))",
            "pid=\(hex(productID))",
            "usagePage=\(hex(primaryUsagePage, width: 2))",
            "usage=\(hex(primaryUsage, width: 2))",
            "interface=\(interfaceNumber.map(String.init) ?? "unknown")",
            "maxFeature=\(maxFeatureReportSize.map(String.init) ?? "unknown")",
            "location=\(hex(locationID, width: 8))",
            "registry=\(registryEntryID.map { "0x" + String($0, radix: 16, uppercase: true) } ?? "unknown")",
            "transport=\(transport ?? "unknown")",
            "flags=\(flags.isEmpty ? "none" : flags)"
        ].joined(separator: " ")
    }
}

extension HIDDeviceInfo {
    init(device: IOHIDDevice) {
        self.registryEntryID = Self.registryEntryID(for: device)
        self.vendorID = Self.intProperty(kIOHIDVendorIDKey, device: device)
        self.productID = Self.intProperty(kIOHIDProductIDKey, device: device)
        self.product = Self.stringProperty(kIOHIDProductKey, device: device)
        self.manufacturer = Self.stringProperty(kIOHIDManufacturerKey, device: device)
        self.serialNumber = Self.stringProperty(kIOHIDSerialNumberKey, device: device)
        self.primaryUsagePage = Self.intProperty(kIOHIDPrimaryUsagePageKey, device: device)
        self.primaryUsage = Self.intProperty(kIOHIDPrimaryUsageKey, device: device)
        self.maxInputReportSize = Self.intProperty(kIOHIDMaxInputReportSizeKey, device: device)
        self.maxOutputReportSize = Self.intProperty(kIOHIDMaxOutputReportSizeKey, device: device)
        self.maxFeatureReportSize = Self.intProperty(kIOHIDMaxFeatureReportSizeKey, device: device)
        self.locationID = Self.intProperty(kIOHIDLocationIDKey, device: device)
        self.interfaceNumber = Self.firstIntProperty(
            ["USB Interface Number", "bInterfaceNumber", "IOHIDInterfaceID"],
            device: device
        )
        self.transport = Self.stringProperty(kIOHIDTransportKey, device: device)
    }

    private static func intProperty(_ key: String, device: IOHIDDevice) -> Int? {
        guard let value = IOHIDDeviceGetProperty(device, key as CFString) else {
            return nil
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            return Int(string)
        }
        return nil
    }

    private static func firstIntProperty(_ keys: [String], device: IOHIDDevice) -> Int? {
        for key in keys {
            if let value = intProperty(key, device: device) {
                return value
            }
        }
        return nil
    }

    private static func stringProperty(_ key: String, device: IOHIDDevice) -> String? {
        guard let value = IOHIDDeviceGetProperty(device, key as CFString) else {
            return nil
        }
        return value as? String
    }

    private static func registryEntryID(for device: IOHIDDevice) -> UInt64? {
        let service = IOHIDDeviceGetService(device)
        guard service != 0 else {
            return nil
        }

        var entryID: UInt64 = 0
        let result = IORegistryEntryGetRegistryEntryID(service, &entryID)
        return result == KERN_SUCCESS ? entryID : nil
    }
}
