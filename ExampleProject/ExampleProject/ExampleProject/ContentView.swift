import LindebrosApiClient
import SwiftUI
import NiceToHave

extension Logger: @retroactive ApiLogger {}

@MainActor
struct ContentView: View {
    let client: ClientProvider
    static let logger = Logger()
    init() {
        client = Client(
            configuration: Client.Configuration(
                baseURL: URL(string: "http://127.0.0.1:8080")!,
                logger: Self.logger
            ),
        )
    }

    @State var state: ViewState = .notLoaded

    func testClient() {
        state = .loading
        Task {
            do {
                let models: [TestModel] = try await self.client.get("/test").dispatch()
                guard let model = models.first else {
                    throw NSError(domain: "Could not find any models", code: 500)
                }
                self.state = .success(model)
                Self.logger.debug("Great success received", model)

                let newModel: TestModel = try await client.post(model, to: "/test", loggingStrategy: .raw).dispatch()

                Self.logger.debug("Great success received new Model", newModel)

                try await client.delete("/test").dispatch()

                Self.logger.debug("Great success testing delete request")

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
                Text(model.title)
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
        var title: String
        var description: String
    }

    enum ViewState {
        case notLoaded
        case loading
        case success(TestModel)
        case error(Error)
    }
}
