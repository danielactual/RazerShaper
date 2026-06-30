import Foundation
import IOKit.hid

public struct HIDDeviceFilter: Equatable, Sendable {
    public var vendorID: Int?
    public var productID: Int?

    public init(vendorID: Int? = nil, productID: Int? = nil) {
        self.vendorID = vendorID
        self.productID = productID
    }

    public static let razer = HIDDeviceFilter(vendorID: RazerConstants.vendorID)
    public static let likelyOuroboros = HIDDeviceFilter(
        vendorID: RazerConstants.vendorID,
        productID: RazerConstants.likelyOuroborosProductID
    )

    public var matchingDictionary: CFDictionary? {
        var matching: [String: Any] = [:]
        if let vendorID {
            matching[kIOHIDVendorIDKey] = vendorID
        }
        if let productID {
            matching[kIOHIDProductIDKey] = productID
        }
        return matching.isEmpty ? nil : matching as CFDictionary
    }
}
