import CoreNFC

final class NFC: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    let data: TransmitData
    var session: NFCNDEFReaderSession?
    @Published var error: String?
    @Published var status = ""
    @Published var tags = ""
    
    init(data: TransmitData) {
        self.data = data
        super.init()
        session = .init(delegate: self, queue: .main, invalidateAfterFirstRead: false)
    }
    
    func start() {
        error = nil
        session?.alertMessage = "You can hold you NFC-tag to the back-top of your iPhone"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        if let message = messages.first {
            self.parse(message: message)
        }
    }
        
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        guard let tag = tags.first else { return }
        
        status = "Connecting to tag: \(tag)"
        Task { @MainActor in
            do {

                try await session.connect(to: tag)
                // READ
                let message = try await tag.readNDEF()
                parse(message: message)

                // WRITE
//                let (status, capacity) = try await tag.queryNDEFStatus()
//                switch status {
//                case .notSupported:
//                    self.error = "Tag is not supported"
//                case .readOnly:
//                    self.error = "Tag is not writable"
//                case .readWrite:
//                    
//                    for (idx, chunk) in data.enumerated() {
//                        if let message = NFCNDEFMessage(data: chunk) {
//                            if message.length > capacity {
//                                self.error = "Tag capacity is too small"
//                            } else {
//                                self.status = "Writing to tag: \(tag)"
//                                try await tag.writeNDEF(message)
//                                self.status = "Writing complete: \(idx + 1)"
//                            }
//                        }
//                    }
//                    session.invalidate()
//                @unknown default:
//                    self.error = "Unknown tag status"
//                }
            } catch {
                self.error = error.localizedDescription
                session.invalidate(errorMessage: error.localizedDescription)
            }
        }
    }
    
    func parse(message: NFCNDEFMessage) {
        let records = message.records.flatMap { record in
            
            let payload: String?
            
            if let text = record.wellKnownTypeTextPayload().0 {
                payload = text
            } else if let url = record.wellKnownTypeURIPayload() {
                payload = url.absoluteString
            } else {
                payload = String(data: record.payload, encoding: .utf8)
            }
            
            return [
                "TNF: \(record.typeNameFormat.name)",
                String(data: record.identifier, encoding: .utf8).map { "ID: \($0)"},
                String(data: record.type, encoding: .utf8).map { "Type: \($0)"},
                payload.map { "Payload: \($0)" }
            ].compactMap { $0 }
        }
        
        self.tags = records.joined(separator: "\n")

    }
    
}
extension NFCTypeNameFormat {
    var name: String {
        switch self {
        case .empty: "Empty"
        case .nfcWellKnown: "NFC Well Known"
        case .media: "Media"
        case .absoluteURI: "Absolute URI"
        case .nfcExternal: "NFC External"
        case .unknown: "Unknown"
        case .unchanged: "Unchanged"
        @unknown default: "New Unknown"
        }
    }
}

extension NFCNDEFStatus {
    var name: String {
        switch self {
        case .notSupported: "Not Supported"
        case .readWrite: "Read Write"
        case .readOnly: "Read Only"
        @unknown default: "Unknown"            
        }
    }
}
//
//extension Sequence {
//    func asyncForEach(_ op: (Element) async throws -> Void) async rethrows {
//        for e in self {
//            try await op(e)
//        }
//    }
//}
