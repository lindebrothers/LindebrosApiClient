import Combine
import Foundation
import LindebrosApiClient
import SwiftUI

class WebSocketContentViewModel: ObservableObject {
    init() {
        webSocketClient = WebSocketClient(config: .init())
        subscriber = webSocketClient.events.sink { event in
            switch event {
            case let .received(message):
                switch message {
                case let .string(text):
                    print("Text", text)
                default:
                    break
                }
            default:
                break
            }
        }
    }

    let webSocketClient: WebSocketClient
    private var subscriber: Cancellable?
}

struct WebSocketContentView: View {
    // let client: Client

    @ObservedObject var viewModel: WebSocketContentViewModel

    var body: some View {
        VStack {
            Button(action: {
                Task { @MainActor in
                    do {
                        try await viewModel
                            .webSocketClient
                            .reconnect()
                            .send(message: "Awesome")
                    } catch {
                        print("💥, Failed to send message with error", error)
                    }
                }
            }) {
                Text("Send to websocket")
            }

            Button(action: {
                viewModel.webSocketClient.connect(to: Client.Request(url: URL(string: "ws://localhost:8080/socket")!)
                    .authenticate(by: Client.Credentials(accessToken: "abc")))
            }) {
                Text("Connect")
            }
            Button(action: {
                viewModel.webSocketClient.disconnect()
            }) {
                Text("Disconnect")
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            let url = URL(string: "ws://localhost:8080/socket")!
            viewModel.webSocketClient.connect(
                to: Client.Request(url: url)
                    .authenticate(by: Client.Credentials(accessToken: "abc"))
            )
        }
    }

    struct TestModel: Codable {
        var message: String
        var subtitle: String
    }

    enum ViewState {
        case notLoaded
        case loading
        case success(TestModel)
        case error(Error)
    }
}
