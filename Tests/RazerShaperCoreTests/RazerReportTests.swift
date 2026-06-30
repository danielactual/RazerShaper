import XCTest
@testable import RazerShaperCore

final class RazerReportTests: XCTestCase {
    func testFirmwareReportMatchesExpectedHeaderAndChecksum() {
        let report = RazerReport.firmwareVersion()

        XCTAssertEqual(report.bytes.count, 90)
        XCTAssertEqual(report.bytes[0], 0x00)
        XCTAssertEqual(report.bytes[1], 0xFF)
        XCTAssertEqual(report.bytes[5], 0x02)
        XCTAssertEqual(report.bytes[6], 0x00)
        XCTAssertEqual(report.bytes[7], 0x81)
        XCTAssertEqual(report.bytes[88], 0x83)
        XCTAssertEqual(report.bytes[89], 0x00)
    }

    func testChecksumIgnoresStatusAndTransactionID() {
        var report = RazerReport.firmwareVersion(transactionID: 0xFF).bytes
        let originalChecksum = report[88]

        report[0] = 0x02
        report[1] = 0x1F

        XCTAssertEqual(RazerReport.checksum(for: report), originalChecksum)
    }

    func testSetDPIUsesBigEndianAxisValues() {
        let report = RazerReport.setDPI(x: 1600, y: 3200)

        XCTAssertEqual(report.bytes[5], 0x07)
        XCTAssertEqual(report.bytes[6], 0x04)
        XCTAssertEqual(report.bytes[7], 0x05)
        XCTAssertEqual(report.bytes[8], 0x01)
        XCTAssertEqual(report.bytes[9], 0x06)
        XCTAssertEqual(report.bytes[10], 0x40)
        XCTAssertEqual(report.bytes[11], 0x0C)
        XCTAssertEqual(report.bytes[12], 0x80)
        XCTAssertEqual(report.bytes[88], RazerReport.checksum(for: report.bytes))
    }

    func testPollingRateArgumentsMatchOpenRazerValues() {
        XCTAssertEqual(RazerReport.setPollingRate(1000).bytes[8], 0x01)
        XCTAssertEqual(RazerReport.setPollingRate(500).bytes[8], 0x02)
        XCTAssertEqual(RazerReport.setPollingRate(125).bytes[8], 0x08)
    }

    func testIdleTimeIsClampedToSupportedRange() {
        let low = RazerReport.setIdleTime(seconds: 10)
        let high = RazerReport.setIdleTime(seconds: 1_000)

        XCTAssertEqual([low.bytes[8], low.bytes[9]], [0x00, 0x3C])
        XCTAssertEqual([high.bytes[8], high.bytes[9]], [0x03, 0x84])
    }
}
