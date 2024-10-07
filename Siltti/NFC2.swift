import CoreNFC
final class NFC2: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    
    let data: TransmitData
    var session: NFCTagReaderSession?
    
    enum Process {
        case status
        case read
        case write
    }
    
    var process: Process?
    @Published var error: String?
    @Published var status = ""
    @Published var log: [String] = []
    
    init(data: TransmitData) {
        self.data = data
        super.init()
    }
    
    func start(process: Process) {
        self.process = process
        error = nil
        log = []
        session = .init(pollingOption: [.iso14443, .iso15693], delegate: self, queue: .main)
        session?.alertMessage = "You can hold you NFC-tag to the back-top of your iPhone"
        session?.begin()
    }
    
    func stop() {
        process = nil
        session?.invalidate()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        self.error = error.localizedDescription

        guard let process = self.process else { return }
        if self.session == nil {
            print("restarting session")
            self.start(process: process)
        } else if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorSystemIsBusy {
            print("system is busy")
            self.start(process: process)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        Task { @MainActor in
            do {
                try await session.connect(to: tag)
                
                if case .iso7816(let isoTag) = tag {
                    
                    var counter = 0
                    while true {
                        switch process {
                        case .status:
                            let status = try await isoTag.queryNDEFStatus()
                            log.append("Status: \(status.0.name), Capacity: \(status.1)")
                        case .read:
                            let message = try await isoTag.readNDEF()
                            log.append("NDEFMessage: \(message)")
                        case .write:
                            if let command = NFCISO7816APDU(data: Data([0,0xa4,0x04, 0x00, 0x7, 0xd4, 0x10, 0x00, 0x00, 0x03, 0x00, 0x01])) {
                                let result = try await isoTag.sendCommand(apdu: command)
                                log.append("Command result: \(result)")
                            } else {
                                error = "Incorrect command"
                                return
                            }
                        case nil:
                            error = "Unknown operation"
                            return
                        }
                        counter += 1
                        log.append("Operations count: \(counter)")
                        //try? await Task.sleep(for: .seconds(1))
                    }
                } else {
                    error = "Unknown tag type"
                }
                
            } catch {
                self.error = error.localizedDescription
                self.session = nil
                session.invalidate()
            }
        }
    }
}
