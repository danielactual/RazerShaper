import Foundation

public enum RazerConstants {
    public static let userReportedModelLabel = "RC30-007701"
    public static let vendorID = 0x1532
    public static let likelyOuroborosProductID = 0x0032
    public static let reportLength = 90
    public static let defaultTransactionID: UInt8 = 0xFF
}

public func hex(_ value: Int?, width: Int = 4) -> String {
    guard let value else {
        return "unknown"
    }
    return "0x" + String(value, radix: 16, uppercase: true).leftPadded(to: width, with: "0")
}

extension String {
    fileprivate func leftPadded(to length: Int, with character: Character) -> String {
        guard count < length else {
            return self
        }
        return String(repeating: String(character), count: length - count) + self
    }
}
