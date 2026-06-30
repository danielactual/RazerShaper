import Foundation

public struct RazerReport: Equatable {
    public enum Status: UInt8 {
        case newCommand = 0x00
        case busy = 0x01
        case success = 0x02
        case notSupported = 0x05
    }

    public enum CommandClass: UInt8 {
        case standard = 0x00
        case led = 0x03
        case dpi = 0x04
        case power = 0x07
    }

    public enum CommandID {
        public static let getFirmwareVersion: UInt8 = 0x81
        public static let setPollingRate: UInt8 = 0x05
        public static let getPollingRate: UInt8 = 0x85
        public static let setDPI: UInt8 = 0x05
        public static let getDPI: UInt8 = 0x85
        public static let getBatteryLevel: UInt8 = 0x80
        public static let getChargingStatus: UInt8 = 0x84
        public static let setLowBatteryThreshold: UInt8 = 0x01
        public static let getLowBatteryThreshold: UInt8 = 0x81
        public static let setIdleTime: UInt8 = 0x03
        public static let getIdleTime: UInt8 = 0x83
        public static let setLEDBrightness: UInt8 = 0x03
    }

    public private(set) var bytes: [UInt8]

    public init(
        transactionID: UInt8 = RazerConstants.defaultTransactionID,
        commandClass: UInt8,
        commandID: UInt8,
        dataSize: UInt8,
        arguments: [UInt8] = []
    ) {
        precondition(arguments.count <= 80, "Razer reports support at most 80 argument bytes.")

        var report = [UInt8](repeating: 0, count: RazerConstants.reportLength)
        report[0] = Status.newCommand.rawValue
        report[1] = transactionID
        report[4] = 0x00
        report[5] = dataSize
        report[6] = commandClass
        report[7] = commandID

        for (index, byte) in arguments.enumerated() {
            report[8 + index] = byte
        }

        report[88] = Self.checksum(for: report)
        report[89] = 0x00
        self.bytes = report
    }

    public var data: Data {
        Data(bytes)
    }

    public var checksum: UInt8 {
        bytes[88]
    }

    public static func checksum(for bytes: [UInt8]) -> UInt8 {
        precondition(bytes.count == RazerConstants.reportLength, "Checksum requires a 90-byte report.")
        return bytes[2...87].reduce(0, ^)
    }
}

public extension RazerReport {
    static func firmwareVersion(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.standard.rawValue,
            commandID: RazerReport.CommandID.getFirmwareVersion,
            dataSize: 0x02
        )
    }

    static func batteryLevel(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.getBatteryLevel,
            dataSize: 0x02
        )
    }

    static func chargingStatus(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.getChargingStatus,
            dataSize: 0x02
        )
    }

    static func setDPI(
        x: UInt16,
        y: UInt16,
        variableStorage: UInt8 = 0x01,
        transactionID: UInt8 = RazerConstants.defaultTransactionID
    ) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.dpi.rawValue,
            commandID: RazerReport.CommandID.setDPI,
            dataSize: 0x07,
            arguments: [
                variableStorage,
                UInt8((x >> 8) & 0xFF),
                UInt8(x & 0xFF),
                UInt8((y >> 8) & 0xFF),
                UInt8(y & 0xFF),
                0x00,
                0x00
            ]
        )
    }

    static func getDPI(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.dpi.rawValue,
            commandID: RazerReport.CommandID.getDPI,
            dataSize: 0x07
        )
    }

    static func setPollingRate(_ pollingRate: Int, transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        let argument: UInt8
        switch pollingRate {
        case 1000:
            argument = 0x01
        case 500:
            argument = 0x02
        case 125:
            argument = 0x08
        default:
            preconditionFailure("Unsupported polling rate: \(pollingRate)")
        }

        return RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.standard.rawValue,
            commandID: RazerReport.CommandID.setPollingRate,
            dataSize: 0x01,
            arguments: [argument]
        )
    }

    static func getPollingRate(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.standard.rawValue,
            commandID: RazerReport.CommandID.getPollingRate,
            dataSize: 0x01
        )
    }

    static func setScrollLEDBrightness(
        _ brightness: UInt8,
        variableStorage: UInt8 = 0x01,
        ledID: UInt8 = 0x01,
        transactionID: UInt8 = RazerConstants.defaultTransactionID
    ) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.led.rawValue,
            commandID: RazerReport.CommandID.setLEDBrightness,
            dataSize: 0x03,
            arguments: [variableStorage, ledID, brightness]
        )
    }

    static func getIdleTime(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.getIdleTime,
            dataSize: 0x02
        )
    }

    static func setIdleTime(seconds: UInt16, transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        let clamped = min(max(seconds, 60), 900)
        return RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.setIdleTime,
            dataSize: 0x02,
            arguments: [UInt8((clamped >> 8) & 0xFF), UInt8(clamped & 0xFF)]
        )
    }

    static func getLowBatteryThreshold(transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.getLowBatteryThreshold,
            dataSize: 0x01
        )
    }

    static func setLowBatteryThreshold(_ threshold: UInt8, transactionID: UInt8 = RazerConstants.defaultTransactionID) -> RazerReport {
        RazerReport(
            transactionID: transactionID,
            commandClass: RazerReport.CommandClass.power.rawValue,
            commandID: RazerReport.CommandID.setLowBatteryThreshold,
            dataSize: 0x01,
            arguments: [threshold]
        )
    }
}
