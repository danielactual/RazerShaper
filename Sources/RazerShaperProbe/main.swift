import Foundation
import RazerShaperCore

enum ProbeCommand: String {
    case list
    case listen
    case packet
    case help
}

struct ProbeOptions {
    var command: ProbeCommand = .help
    var filter = HIDDeviceFilter.razer
    var seconds: TimeInterval = 30
    var packetName = "firmware"
    var includeMotion = false
    var includeVendorDefined = false
}

@main
enum RazerShaperProbe {
    static func main() {
        do {
            let options = try parseOptions(Array(CommandLine.arguments.dropFirst()))
            switch options.command {
            case .list:
                try listDevices(filter: options.filter)
            case .listen:
                try listen(options: options)
            case .packet:
                printPacket(named: options.packetName)
            case .help:
                printUsage()
            }
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n\n".utf8))
            printUsage()
            Foundation.exit(1)
        }
    }

    private static func listDevices(filter: HIDDeviceFilter) throws {
        let devices = try HIDDeviceEnumerator().devices(matching: filter)

        if devices.isEmpty {
            print("No HID devices matched \(describe(filter: filter)).")
            return
        }

        print("Matched \(devices.count) HID device(s) for \(describe(filter: filter)):")
        for (index, device) in devices.enumerated() {
            print("[\(index)] \(device)")
        }
    }

    private static func listen(options: ProbeOptions) throws {
        let devices = try HIDDeviceEnumerator().devices(matching: options.filter)
        print("Listening for HID input from \(describe(filter: options.filter)).")
        print("Matched \(devices.count) current device(s). Press mouse buttons now.")
        if options.seconds > 0 {
            print("The listener will stop after \(Int(options.seconds)) second(s).")
        } else {
            print("The listener will run until interrupted.")
        }

        print("Default listener output hides pointer motion and vendor-defined reports. Use --raw to show everything.")

        let logger = HIDInputLogger(filter: options.filter) { event in
            guard shouldPrint(event: event, options: options) else {
                return
            }
            print(event)
            fflush(stdout)
        }
        try logger.start()

        if options.seconds > 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(options.seconds))
            logger.stop()
        } else {
            RunLoop.current.run()
        }
    }

    private static func printPacket(named name: String) {
        let report: RazerReport
        switch name {
        case "firmware":
            report = .firmwareVersion()
        case "battery":
            report = .batteryLevel()
        case "charging":
            report = .chargingStatus()
        case "dpi":
            report = .getDPI()
        case "polling":
            report = .getPollingRate()
        default:
            print("Unknown packet '\(name)'. Known packets: firmware, battery, charging, dpi, polling")
            return
        }

        print(report.bytes.map { String(format: "%02X", $0) }.joined(separator: " "))
    }

    private static func parseOptions(_ arguments: [String]) throws -> ProbeOptions {
        var options = ProbeOptions()
        var index = 0

        if let first = arguments.first, !first.hasPrefix("--") {
            options.command = ProbeCommand(rawValue: first) ?? .help
            index = 1
        }

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--all":
                options.filter = HIDDeviceFilter()
            case "--vendor":
                index += 1
                options.filter.vendorID = try parseRequiredInt(arguments, at: index, name: "--vendor")
            case "--product":
                index += 1
                options.filter.productID = try parseRequiredInt(arguments, at: index, name: "--product")
            case "--likely-ouroboros":
                options.filter = .likelyOuroboros
            case "--seconds":
                index += 1
                options.seconds = TimeInterval(try parseRequiredInt(arguments, at: index, name: "--seconds"))
            case "--packet":
                index += 1
                options.packetName = try parseRequiredString(arguments, at: index, name: "--packet")
            case "--include-motion":
                options.includeMotion = true
            case "--include-vendor":
                options.includeVendorDefined = true
            case "--raw":
                options.includeMotion = true
                options.includeVendorDefined = true
            default:
                throw ProbeError.invalidArgument(argument)
            }
            index += 1
        }

        return options
    }

    private static func parseRequiredString(_ arguments: [String], at index: Int, name: String) throws -> String {
        guard arguments.indices.contains(index) else {
            throw ProbeError.missingValue(name)
        }
        return arguments[index]
    }

    private static func parseRequiredInt(_ arguments: [String], at index: Int, name: String) throws -> Int {
        let string = try parseRequiredString(arguments, at: index, name: name)
        if string.lowercased().hasPrefix("0x") {
            guard let value = Int(string.dropFirst(2), radix: 16) else {
                throw ProbeError.invalidInteger(string)
            }
            return value
        }
        guard let value = Int(string) else {
            throw ProbeError.invalidInteger(string)
        }
        return value
    }

    private static func describe(filter: HIDDeviceFilter) -> String {
        if filter.vendorID == nil && filter.productID == nil {
            return "all HID devices"
        }

        var parts: [String] = []
        if let vendorID = filter.vendorID {
            parts.append("vid=\(hex(vendorID))")
        }
        if let productID = filter.productID {
            parts.append("pid=\(hex(productID))")
        }
        return parts.joined(separator: " ")
    }

    private static func shouldPrint(event: HIDInputEvent, options: ProbeOptions) -> Bool {
        if !options.includeMotion && event.isGenericDesktopMotion {
            return false
        }
        if !options.includeVendorDefined && event.isVendorDefined {
            return false
        }

        if options.includeMotion || options.includeVendorDefined {
            return true
        }

        return event.isDefaultProbeEvent
    }

    private static func printUsage() {
        print("""
        RazerShaperProbe

        Usage:
          RazerShaperProbe list [--all] [--vendor 0x1532] [--product 0x0032] [--likely-ouroboros]
          RazerShaperProbe listen [--all] [--vendor 0x1532] [--product 0x0032] [--likely-ouroboros] [--seconds 30] [--raw]
          RazerShaperProbe packet [--packet firmware|battery|charging|dpi|polling]

        Defaults:
          list/listen match all Razer HID devices with vendor ID 0x1532.
          --likely-ouroboros narrows to VID 0x1532 and PID 0x0032.
          --seconds 0 listens until interrupted.
          listen hides pointer motion and vendor-defined reports unless --include-motion, --include-vendor, or --raw is passed.
        """)
    }
}

enum ProbeError: Error, CustomStringConvertible {
    case invalidArgument(String)
    case missingValue(String)
    case invalidInteger(String)

    var description: String {
        switch self {
        case .invalidArgument(let argument):
            return "invalid argument \(argument)"
        case .missingValue(let option):
            return "missing value for \(option)"
        case .invalidInteger(let value):
            return "invalid integer \(value)"
        }
    }
}
