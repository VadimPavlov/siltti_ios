import SwiftUI
import AVFoundation

@MainActor
final class MainModel: ObservableObject {
    @Published var authorized: Bool?
    @Published var scanned = ""
    @Published var status = ""
    @Published var progress = ""
    @Published var transmit: TransmitData?
    
    let collection = Collection()
    
    init() {
        scanned = ipsum
        if let data = ipsum.data(using: .utf8) {
            transmit = chunk(data: data)
        }
    }

    func authorize() async {
        authorized = await AVCaptureDevice.requestAccess(for: .video)
    }
    
    func clear() {
        scanned = ""
        status = ""
        transmit = nil
        do {
            try collection.clean()
            refreshFrames()
        } catch {
            status = error.localizedDescription
        }
    }
    
    func scanned(data: Data) {
        do {
            
            scanned = data.latin ?? ""
            
            transmit = chunk(data: data)
            
            /*
            let result = try collection.processFrame(rawFrame: data)
            if let payload = result.payload {
                let action = try Action.newPayload(payload: payload, dbPath: "test_db", signatureMaker: Signer())
                if let packet = action.makePacket() {
                    transmit = packet
                    
                    if !action.isTransmit() {
                        status = "Payload accepted"
                    }
                } else {
                    status = "Packet is empty"
                }
            } else {
                refreshFrames()
            }
             */
        } catch {
            status = error.localizedDescription
        }
    }
    
    func chunk(data: Data, size: Int = 254) -> [Data] {
        var chunks: [Data] = []
        data.withUnsafeBytes { bytes in
            let pointer = UnsafeMutableRawPointer(mutating: bytes)
            let total = data.endIndex
            var offset = 0
            
            while offset < total {
                let chunkSize = offset + size > total ? total - offset : size
                let chunk = Data(bytesNoCopy: pointer, count: chunkSize, deallocator: .none)
                offset += chunkSize
                chunks.append(chunk)
            }
        }
        return chunks
    }
    
    func refreshFrames() {
        do {
            if let frames = try collection.frames() {
                progress = "\(frames.current) / \(frames.total)"
            } else {
                progress = ""
            }
        } catch {
            status = error.localizedDescription
        }
    }
}

struct MainScreen: View {
    @StateObject var model = MainModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    cameraView
                        .ignoresSafeArea(.all)
                    footerView
                        .padding(.horizontal)
                }.frame(maxHeight: .infinity)
            }
        }
        .task {
            await model.authorize()
        }

    }
    
    @ViewBuilder
    var cameraView: some View {
        if model.authorized == true {
            ScannerView(types: [.qr]) { data in
                model.scanned(data: data)
            }
        } else {
            Button("Open settings and allow camera permission") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    var footerView: some View {
        VStack {
            Text(model.status).foregroundStyle(.red)
            ScrollView {
                Text(model.scanned)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .border(Color.black)
            HStack {
                Group {
                    Button("Clear") {
                        model.clear()
                    }
                    NavigationLink("Transmit") {
                        if let data = model.transmit {
                            TransmitScreen(data: data)
                        } else {
                            EmptyView()
                        }
                    }.disabled(model.transmit == nil)
                    
                }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    MainScreen()
}

extension Data {
    var latin: String? {
        String(data: self, encoding: .isoLatin1)
    }
}

class Signer: SignByCompanion {
    func makeSignature(data: Data) -> Data {
        Data()
    }
    
    func exportPublicKey() -> Data {
        Data()
    }
    
}

extension ErrorCompanion: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .Base58PrefixFormatNotSupported(let message): message
            
        case .Base58PrefixMismatch(let message): message
            
        case .BlockHashFormat(let message): message
            
        case .Client(let message): message
            
        case .DbInternal(let message): message
            
        case .DbTransaction(let message): message
            
        case .DecimalsFormatNotSupported(let message): message
            
        case .DecodeDbAddress(let message): message
            
        case .DecodeDbKey(let message): message
            
        case .DecodeDbMetadataSpecs(let message): message
            
        case .GenesisHashFormat(let message): message
        
        case .GenesisHashLength(let message): message
            
        case .InterfaceKey(let message): message
            
        case .LoadSpecsMetadata(let message): message
            
        case .LostAddress(let message): message
            
        case .LtError(let message): message
            
        case .MetaCut(let message): message
            
        case .MetadataFetchWithoutExistingEntry(let message): message
        
        case .MetadataFormat(let message): message
            
        case .MetadataNotDecodeable(let message): message
            
        case .MetadataVersion(let message): message
            
        case .NoBase58Prefix(let message): message
            
        case .NoDecimals(let message): message
            
        case .NoExistingEntryMetadataUpdate(let message): message
            
        case .NoMetadataV15(let message): message
            
        case .NoMetaPrefix(let message): message
            
        case .NotHex(let message): message
            
        case .NotSent(let message): message
            
        case .NotSubstrate(let message): message
            
        case .NoUnit(let message): message
            
        case .OnlySr25519(let message): message
            
        case .PoisonedLockSelector(let message): message
            
        case .PropertiesFormat(let message): message
            
        case .RawMetadataNotDecodeable(let message): message
            
        case .ReceiverClosed(let message): message
            
        case .ReceiverGuardPoisoned(let message): message
            
        case .RequestSer(let message): message
            
        case .ResponseDe(let message): message
            
        case .TooShort(let message): message
            
        case .TransactionNotParsable(let message): message
            
        case .UnexpectedFetch(let message): message
            
        case .UnitFormatNotSupported(let message): message
            
        case .UnknownPayloadType(let message): message
            
        case .UpdateMetadata(let message): message
            
        }
    }
}


let ipsum = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam dapibus bibendum risus eget luctus. Etiam vitae nunc vitae enim dapibus gravida et sit amet leo. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Donec vehicula purus sed nulla laoreet, vel lacinia risus lacinia. In hac habitasse platea dictumst. Etiam a sodales velit. Vestibulum at convallis mi, vitae blandit arcu. Sed porttitor, leo in dapibus mattis, purus velit posuere ex, id consectetur nibh purus eu risus. Phasellus velit odio, mollis at convallis eget, hendrerit dapibus ante. Fusce iaculis, nunc sed rutrum auctor, lorem turpis egestas libero, a auctor lacus sapien condimentum lacus. Curabitur hendrerit sapien ut nisi sollicitudin ultricies. Etiam viverra sit amet mauris id pharetra.

Praesent vulputate velit at bibendum auctor. Nam eleifend porta nulla, id suscipit lectus varius vel. Maecenas vitae purus felis. Donec hendrerit tristique libero ut mollis. Suspendisse posuere est in commodo condimentum. Nullam commodo tempus tincidunt. Maecenas vehicula porta odio, id varius ipsum accumsan sed. Duis sed sem in lacus bibendum posuere et nec justo. Donec auctor sem eget iaculis ultrices. Vivamus placerat nibh nunc, vitae gravida sapien ullamcorper a. Nunc pharetra lobortis massa sit amet varius. Sed rhoncus ligula nec quam aliquet, eget efficitur lacus congue. Ut varius at justo nec finibus. Morbi fermentum vel metus sed consequat. Nullam elementum sem eget augue elementum accumsan. Etiam sed lorem neque.

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi eros nulla, consequat ac nisi sit amet, scelerisque sollicitudin elit. Praesent porta nunc nisl, ac mollis est finibus eu. In eget aliquam nisl. Mauris eu orci eget purus ornare lacinia pharetra id nisi. Quisque sollicitudin, urna id efficitur faucibus, urna mauris tempus velit, in rhoncus ipsum magna at dolor. Morbi eu consectetur leo, ut efficitur sem. Nulla accumsan ipsum nec felis euismod, eu fermentum leo scelerisque. Fusce eget imperdiet lorem. Sed fringilla libero mi, a volutpat elit interdum in. Quisque lectus felis, fermentum quis ullamcorper sit amet, semper a urna. Quisque fermentum, eros eu viverra euismod, odio urna congue magna, ut ultricies leo neque in eros. Nam purus tortor, pulvinar ut tempus vitae, aliquet condimentum ligula. Cras lectus purus, auctor eget mi a, pharetra feugiat elit. Aenean vestibulum ligula sit amet nunc iaculis, condimentum tincidunt mauris eleifend. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Etiam ut sapien sem. Fusce a sollicitudin erat. Maecenas at molestie leo. Phasellus a magna purus. Etiam eu bibendum nisl. Donec et turpis volutpat, euismod augue tempor, mattis leo. Morbi lectus velit, porta sed consequat ac, iaculis vitae lacus. Sed laoreet aliquet felis elementum auctor. Etiam convallis lacus sit amet arcu rhoncus, id sodales nunc tincidunt. Integer sed pellentesque nulla, in vulputate arcu. Suspendisse at ex facilisis, condimentum enim nec, eleifend lectus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;

Fusce porta quam id facilisis rutrum. Suspendisse vitae congue justo. In at mattis eros. Mauris finibus ex dui, ut suscipit nibh facilisis vitae. Aliquam fermentum bibendum vulputate. Etiam dapibus, neque in luctus hendrerit, nisl sem malesuada neque, eu venenatis justo eros eu arcu. Nunc vitae bibendum mauris, semper consectetur ex. Nam imperdiet placerat velit. Donec aliquam metus in condimentum blandit. Mauris non dictum nunc, tempus vestibulum justo. Aliquam ac dignissim risus, ut luctus leo.

"""
