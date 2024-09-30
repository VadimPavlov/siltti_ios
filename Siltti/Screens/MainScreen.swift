import SwiftUI
import AVFoundation

@MainActor
final class MainModel: ObservableObject {
    @Published var authorized: Bool?
    @Published var scanned = ""
    
    func authorize() async {
        authorized = await AVCaptureDevice.requestAccess(for: .video)
        scanned = sayHello(to: "Rust!")
    }
    
    func sayHello(to: String) -> String {
        let result = rust_greeting(to)
        let swift_result = String(cString: result!)
        rust_greeting_free(UnsafeMutablePointer(mutating: result))
        return swift_result
    }
}

struct MainScreen: View {
    @StateObject var model = MainModel()
    
    var body: some View {
        VStack {
            Group {
                cameraView
                    .ignoresSafeArea(.all)
                footerView
                    .padding(.horizontal)
            }.frame(maxHeight: .infinity)
        }
        .task {
            await model.authorize()
        }
    }
    
    @ViewBuilder
    var cameraView: some View {
        if model.authorized == true {
            ScannerView(types: [.qr]) { result in
                model.scanned = result
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
            ScrollView {
                Text(model.scanned)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .border(Color.black)
            HStack {
                Group {
                    Button("Process") {
                        
                    }
                    
                    Button("Transmit") {
                        
                    }
                }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    MainScreen()
}
