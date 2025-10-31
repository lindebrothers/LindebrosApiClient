import LindebrosApiClient
import SwiftUI
import NiceToHave

extension Logger: @retroactive ApiLogger {}

@MainActor
struct ContentView: View {
    let client: Client
    static let logger = Logger()
    init() {
        client = Client(
            configuration: Client.Configuration(
                baseURL: URL(string: "https://foaas.com")!,
                logger: Self.logger
            ),
        )
    }

    @State var state: ViewState = .notLoaded

    func testClient() {
        state = .loading
        Task {
            do {
                if let model: TestModel = try await self.client.get("/awesome/LindebrosApiClient").dispatch() {
                    self.state = .success(model)
                }
            } catch {
                Self.logger.error("Failed to fetch with error", error)
                self.state = .error(error)
            }
        }
    }

    var body: some View {
        VStack {
            switch state {
            case .notLoaded:
                EmptyView()
            case .loading:
                ProgressView()
            case let .success(model):
                Text(model.message)
            case let .error(error):
                Text(error.localizedDescription)
            }
            Button(action: {
                testClient()
            }) {
                Text("Load")
            }
        }
        .frame(width: 400, height: 300)
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
