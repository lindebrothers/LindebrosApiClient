# LindebrosClient
LindebrosClient is a client written in Swift. It is a `URLSession` implementation that makes it easy and convenient to make requests to a backend server.


## Get Started
1. Install the client using the Swift Package Manager.
    ```Swift
    dependencies: [
        .package(url: "https://github.com/lindebrothers/LindebrosClient.git", .upToNextMajor(from: "2.0.2"))
    ]
    ```
## How to use it

### GET requests
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)

do {
    let model: Model? = try await Client(config).get("/hello/world").dispatch()
} catch let e {
    // Handle errors
}
```
Fetch with querystring params
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)
let query = ParameterState(queryString: "a=b&c=d")
do {
    let model: Model? = try await Client(config).get("/hello/world", with: query).dispatch()
} catch let e {
    // Handle errors
}
```

### POST requests
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)

struct PostData: Encodable {
    var test: String
} 
do {
    let model: Model? = try await Client(config)
    .post(PostData(test: "Andy"), to: "/hello/world").dispatch()
} catch let e {
    // Handle errors
}
```

If you need to send a post request using form data you set `contentType` to `.form`. Default is `.json`

``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)

struct PostData: Encodable {
    var test: String
} 
do {
    let model: Model? = try await Client(config)
    .post(PostData(test: "Andy"), to: "/hello/world", contentType: .form)
    .dispatch()
} catch let e {
    // Handle errors
}
```

### PUT requests
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)

struct PostData: Encodable {
    var test: String
} 
do {
    let model: Model? = try await Client(config)
    .put(PostData(test: "Andy"), to: "/hello/world/1")
    .dispatch()
} catch let e {
    // Handle errors
}
```
### Delete requests
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)
struct PostData: Encodable {
    var test: String
} 
do {
    let model: Model? = try await Client(config)
    .delete("/hello/world/1")
    .dispatch()
} catch let e {
    // Handle errors
}
```
### Set auth token
``` Swift
    let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)
    
    let model: Model? = try await Client(config)
    .get("/hello/world/1")
    .authenticate(by: "abc")
    .dispatch()
```

### Custom request
If you need to create a custom request with custom headers you can use the `endpoint` function.
``` Swift
let config = Client.Configuration(baseURL: URL(string: "https://someapi.com")!)
struct PostData: Encodable {
    var test: String
}
do {
    let model: Model? = try await Client(config)
        .endpoint("/hello/world")
        .setMethod(.post)
        .setHeader(key: "Set-Cookie", value: "cool=awesome;")
        .setContentType(.form)
        .setBody(model: PostData(test: "Andy"))
        .asyncRequest(urlSession: configuration.urlSession) // This function makes the request
        
} catch let e {
    // Handle errors
}
```

## Fetch client tokens for anonymous requests.
The Client can call a authenticator service when the server responds with unauthorized (401) or forbidden (403).

To enable this, provide client credentals in the configuration.
```Swift

    class CredentialsManager: CredentialsProvider, AuthenticatorProvider {
        var credentials: Client.Credentials?

        func provideCredentials() -> Client.Credentials? {
            // credentials can here for example be fetched from keychain 
            return credentials
        }

        func setCredentials(to credentials: Client.Credentials) {
            // credentials can here be saved to for example keychain
            self.credentials = credentials
        }
        
        func fetchNewCredentials() async -> Client.Credentials? {
            // make login request and return Client.Credentials
            return Client.Credentials()
        }
    }

    let client = Client(Client.Configuration(
        baseURL: URL(string: "https://someapi.com")!, 
        credentialsProvider: CredentialsManager()
    ))
```

## Mocking the Client
You can mock the client by mocking the URLSession. In the configuration, apply your mockObject to the urlSession attribute in the configuration.
```Swift

struct URLSessionSpy: URLSessionProvider {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let model = try JSONEncoder().encode(Model())
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    continuation.resume(returning: (model, urlResponse))
                catch let e {
                    continuation.resume(throwing: e)
                }
            }
        }
    }
}

let client = Client(Client.Configuration(
    baseURL: URL(string: "https://someapi.io")!,
    urlSession: URLSessionSpy(),
    credentials: CredentialsMock.self
))

do {
    let ad: Model? = try await client.get("/models/123").dispatch()
} catch let e {
    // Handle error
}
```


## Websocket client
LindebrosApiClient comes with a websocket client as well as a http client.
Here's an example of an implementation of the websocket client
``` Swift
import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    init() {
        webSocketClient = WebSocketClient(config: .init())
        subscriber = webSocketClient.events.sink { [weak self] event in
            switch event{
            case .stateChanged:
                print("state changed to", self?.webSocketClient.state ?? .disconnected)
            case let .received(message):
                print("received message", message)
            }
        }
    }
    
    let webSocketClient: WebSocketClient
    private var subscriber: Cancellable?
}

struct ContentView: View {
    let viewModel = ContentViewModel()

    var body: some View {
        VStack {
            Button(action: {
                Task {
                    do {
                        try await viewModel.webSocketClient.send(message: "Awesome")
                    } catch {
                        print("💥, Failed to send message with error", error)
                    }
                }
            }) {
                Text("Send to websocket")
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            let url = URL(string: "ws://localhost:8080/socket")!
            viewModel.webSocketClient.dispatch(.connect(to: url))
        }
    }
 }
 ```
