import Foundation
import IOKit
import IOKit.hid

public struct HIDFeatureReportResult: CustomStringConvertible {
    public let device: HIDDeviceInfo
    public let request: [UInt8]
    public let response: [UInt8]
    public let setResult: IOReturn
    public let getResult: IOReturn

    public var statusByte: UInt8? {
        response.first
    }

    public var description: String {
        [
            "device={\(device.description)}",
            "set=\(formatIOReturn(setResult))",
            "get=\(formatIOReturn(getResult))",
            "status=\(statusByte.map { String(format: "0x%02X", $0) } ?? "unknown")",
            "response=\(response.map { String(format: "%02X", $0) }.joined(separator: " "))"
        ].joined(separator: "\n")
    }
}

public struct HIDFeatureReportClient {
    public init() {}

    public func sendReadOnlyReport(_ report: RazerReport, matching filter: HIDDeviceFilter = .likelyOuroboros) throws -> HIDFeatureReportResult {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, filter.matchingDictionary)

        let managerOpenResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard managerOpenResult == kIOReturnSuccess else {
            throw HIDError(operation: "IOHIDManagerOpen", code: managerOpenResult)
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        guard let device = try controlDevice(from: manager) else {
            throw HIDFeatureReportError.controlInterfaceNotFound
        }

        let deviceOpenResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard deviceOpenResult == kIOReturnSuccess || deviceOpenResult == kIOReturnExclusiveAccess else {
            throw HIDError(operation: "IOHIDDeviceOpen", code: deviceOpenResult)
        }
        defer {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        let request = report.bytes
        let setResult = request.withUnsafeBytes { buffer in
            IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(0),
                buffer.bindMemory(to: UInt8.self).baseAddress!,
                request.count
            )
        }

        Thread.sleep(forTimeInterval: 0.3)

        var response = [UInt8](repeating: 0, count: RazerConstants.reportLength)
        var responseLength = response.count
        let getResult = response.withUnsafeMutableBytes { buffer in
            IOHIDDeviceGetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(0),
                buffer.bindMemory(to: UInt8.self).baseAddress!,
                &responseLength
            )
        }

        if responseLength < response.count {
            response.removeLast(response.count - responseLength)
        }

        return HIDFeatureReportResult(
            device: HIDDeviceInfo(device: device),
            request: request,
            response: response,
            setResult: setResult,
            getResult: getResult
        )
    }

    private func controlDevice(from manager: IOHIDManager) throws -> IOHIDDevice? {
        guard let deviceSet = IOHIDManagerCopyDevices(manager) else {
            return nil
        }

        let devices = HIDDeviceEnumerator.devices(from: deviceSet)
        return devices.first { device in
            HIDDeviceInfo(device: device).maxFeatureReportSize == RazerConstants.reportLength
        } ?? devices.first
    }
}

public enum HIDFeatureReportError: Error, CustomStringConvertible {
    case controlInterfaceNotFound

    public var description: String {
        switch self {
        case .controlInterfaceNotFound:
            return "No HID control interface with a usable feature report endpoint was found."
        }
    }
}
