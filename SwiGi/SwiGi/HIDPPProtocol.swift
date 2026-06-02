import Foundation

enum HIDPPProtocol {
    private static let pingMessage: Data = {
        let requestID = UInt16(HIDPPConstants.featureRoot << 8) | UInt16(HIDPPConstants.swID)
        let params = Data([0x00, 0x00, 0x00])
        return buildMessage(devnumber: HIDPPConstants.devnumberDirect, requestID: requestID, params: params)
    }()

    static var ping: Data { pingMessage }

    static func buildMessage(devnumber: UInt8, requestID: UInt16, params: Data) -> Data {
        var data = Data()
        data.append(HIDPPConstants.reportLong)
        data.append(devnumber)
        var header = Data()
        header.append(contentsOf: withUnsafeBytes(of: requestID.bigEndian) { Data($0) })
        header.append(params)
        if header.count < 18 {
            header.append(Data(repeating: 0, count: 18 - header.count))
        } else {
            header = header.prefix(18)
        }
        data.append(header)
        return data
    }

    static func packParams(_ params: [Any]) -> Data {
        var data = Data()
        for param in params {
            if let byte = param as? UInt8 {
                data.append(byte)
            } else if let intVal = param as? Int {
                data.append(UInt8(intVal & 0xFF))
            } else if let bytes = param as? Data {
                data.append(bytes)
            }
        }
        return data
    }

    static func hidppRequest(
        transport: HIDTransport,
        devnumber: UInt8,
        requestID: UInt16,
        params: [Any] = [],
        timeout: Int = 500
    ) -> Data? {
        let maskedRequestID = (requestID & 0xFFF0) | UInt16(HIDPPConstants.swID)
        let paramsBytes = packParams(params)
        var requestData = Data()
        requestData.append(contentsOf: withUnsafeBytes(of: maskedRequestID.bigEndian) { Data($0) })
        requestData.append(paramsBytes)
        let message = buildMessage(devnumber: devnumber, requestID: maskedRequestID, params: paramsBytes)

        do {
            try transport.write(message)
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(Double(timeout) / 1000.0)
        while Date() < deadline {
            let raw: Data
            do {
                guard let data = try transport.read(timeout: timeout) else { continue }
                raw = data
            } catch {
                return nil
            }

            guard raw.count >= 4 else { continue }
            let reportID = raw[0]
            guard let expectedLen = HIDPPConstants.msgLengths[reportID], raw.count == expectedLen else { continue }

            let rdev = raw[1]
            guard rdev == devnumber || rdev == (devnumber ^ 0xFF) else { continue }

            let rdata = raw.dropFirst(2)
            if reportID == HIDPPConstants.reportShort,
               rdata.first == 0x8F,
               rdata.prefix(2) == requestData.prefix(2) {
                return nil
            }
            if rdata.first == 0xFF, rdata.prefix(2) == requestData.prefix(2) {
                return nil
            }
            if rdata.prefix(2) == requestData.prefix(2) {
                return Data(rdata.dropFirst(2))
            }
        }
        return nil
    }

    static func resolveFeature(transport: HIDTransport, devnumber: UInt8, featureCode: UInt16) -> UInt8? {
        let requestID = UInt16((HIDPPConstants.featureRoot << 8) | 0x00)
        guard let reply = hidppRequest(
            transport: transport,
            devnumber: devnumber,
            requestID: requestID,
            params: [UInt8(featureCode >> 8), UInt8(featureCode & 0xFF), 0x00]
        ), reply.first != 0x00 else {
            return nil
        }
        return reply.first
    }

    static func getDeviceType(transport: HIDTransport, devnumber: UInt8, featureIndex: UInt8) -> UInt8? {
        let requestID = UInt16((UInt16(featureIndex) << 8) | 0x20)
        return hidppRequest(transport: transport, devnumber: devnumber, requestID: requestID)?.first
    }

    static func getDeviceName(transport: HIDTransport, devnumber: UInt8, featureIndex: UInt8) -> String? {
        let baseRequestID = UInt16((UInt16(featureIndex) << 8) | 0x00)
        guard let reply = hidppRequest(transport: transport, devnumber: devnumber, requestID: baseRequestID) else {
            return nil
        }
        let nameLen = Int(reply.first ?? 0)
        guard nameLen > 0 else { return nil }

        var chars = [UInt8]()
        while chars.count < nameLen {
            let chunkRequestID = UInt16((UInt16(featureIndex) << 8) | 0x10)
            guard let chunk = hidppRequest(
                transport: transport,
                devnumber: devnumber,
                requestID: chunkRequestID,
                params: [UInt8(chars.count)]
            ) else {
                break
            }
            chars.append(contentsOf: chunk.prefix(nameLen - chars.count))
        }
        guard !chars.isEmpty else { return nil }
        return String(bytes: chars, encoding: .utf8)
    }

    static func sendChangeHost(transport: HIDTransport, devnumber: UInt8, featureIndex: UInt8, targetHost: UInt8) throws {
        let requestID = UInt16((UInt16(featureIndex) << 8) | (UInt16(HIDPPConstants.changeHostFnSet) & 0xF0) | UInt16(HIDPPConstants.swID))
        let params = Data([targetHost])
        let message = buildMessage(devnumber: devnumber, requestID: requestID, params: params)
        try transport.write(message)
    }
}
