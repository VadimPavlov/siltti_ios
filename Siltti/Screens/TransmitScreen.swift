import SwiftUI

typealias TransmitData = Action

struct TransmitScreen: View {
    @StateObject var nfc: NFC2
    @Environment(\.dismiss) var dismiss
    
    init(data: TransmitData) {
        _nfc = .init(wrappedValue: NFC2(data: data))
    }
    
    var body: some View {
        VStack {
            ScrollView {
                if let error = nfc.error {
                    Text(error).foregroundStyle(.red)
                } else {
                    Text(nfc.status).foregroundStyle(.green)
                }
                
                Text(nfc.log.reversed().joined(separator: "\n")).padding(.top)
            }
            HStack {
                Group {
                    Button("Status") {
                        nfc.start(process: .status)
                    }
                    Button("Read") {
                        nfc.start(process: .read)
                    }
                    Button("Write") {
                        nfc.start(process: .write)
                    }
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
        }
        .navigationTitle("Transmit")
        .onDisappear {
            nfc.stop()
        }
    }
}
