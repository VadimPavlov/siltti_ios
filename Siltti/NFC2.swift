import CoreNFC

#if DEBUG
typealias Session = NFCTagReaderSession
#else
typealias Session = NFCNDEFReaderSession
#endif


final class NFC2: NSObject, ObservableObject {
    
    let data: TransmitData
    var session: Session?
    
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
#if !DEBUG
        session = .init(delegate: self, queue: .main, invalidateAfterFirstRead: false)
#else
        session = .init(pollingOption: [.iso14443], delegate: self, queue: .main)
#endif
        session?.alertMessage = "You can hold you NFC-tag to the back-top of your iPhone"
        session?.begin()
    }
    
    func stop() {
        process = nil
        session?.invalidate()
    }
    
    func handle(error: any Error) {
        //        guard let process = self.process else { return }
        //        DispatchQueue.main.async {
        //            if self.session == nil {
        //                print("restarting session")
        //                self.start(process: process)
        //            } else if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorSystemIsBusy {
        //                print("system is busy")
        //                self.start(process: process)
        //            }
        //            self.error = error.localizedDescription
        //        }
    }
}

extension NFC2: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        error = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        handle(error: error)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
    }
}

extension NFC2: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        error = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        handle(error: error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        Task { @MainActor in
            do {
                try await session.connect(to: tag)
                
                switch tag {
                case .feliCa(let felicaTag): print(felicaTag)
                case .iso15693(let isoTag): print(isoTag)
                case .miFare(let mifareTag): print(mifareTag)
                case .iso7816(let isoTag):
                    let aids: [String] = [
                        //                        "A000000003",    // GlobalPlatform
                        //                        "A000000004",    // ISO 7816 Application
                        //                        "A000000025",    // Issuer Identification
                        //                        "A000000063",    // UnionPay
                        //                        "A0000002471001", // Example AID 1 (could be a specific service)
                        //                        "A0000002472001", // Example AID 2 (could be a specific service)
                        //                        "D2760000850100", // NFC Forum Application 1
                        "D2760000850101", // NFC Forum Application 2
                        //                        "D2760001180101",
                        //                        "A0000000031010", // Visa Credit
                        //                        "A0000000032010", // Visa Debit
                        //                        "A0000000041010", // MasterCard
                        //                        "A0000000250101", // American Express
                        //                        "A000000555",     // Public Transport Services
                        //                        "A000000008",     // Calypso Cards
                        //                        "A000000040",     // National ID Applications
                        //                        "A000000010"      // NFC Forum Application
                    ]
                    
                    
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
//                            for aid in aids {
//                                let data = aid.hex
//                                let select = NFCISO7816APDU(instructionClass: 0x00, instructionCode: 0xA4, p1Parameter: 0x04, p2Parameter: 0,
//                                                            data: data, expectedResponseLength: -1)
//                                if let (_, sw1, sw2) = try? await isoTag.sendCommand(apdu: select) {
//                                    if sw1 == 0x90 && sw2 == 0x00 {
//                                        print("\(aid) IS SUPPORTED")
//                                    } else {
//                                        print("\(aid) IS NOT SUPPORTED")
//                                    }
//                                } else {
//                                    print("\(aid) fails due to entitlement")
//                                }
//                            }
                            //if counter > 50 { // wait for 5 seconds before sending packets
                                if let packet = data.makePacket() {
                                    let command = NFCISO7816APDU(instructionClass: 0x00, instructionCode: 0x00,
                                                                 p1Parameter: 0x00, p2Parameter: 0x00,
                                                                 data: packet, expectedResponseLength: -1)
                                    let response = try await isoTag.sendCommand(apdu: command)
                                    log.append("\(response)")
                                } else {
                                    error = "Empty packet"
                                }//                                
//                            } else {
//                                try await Task.sleep(for: .milliseconds(100))
//                            }
                        case nil:
                            error = "Unknown operation"
                            return
                        }
                        counter += 1
                        log.append("Operations count: \(counter)")
                    }
                @unknown default:
                    error = "Uknown tag type"
                }
                
            } catch {
                self.error = error.localizedDescription
                self.session = nil
                session.invalidate()
            }
        }
    }
}
