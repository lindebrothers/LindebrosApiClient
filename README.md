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
The Client can fetch new client tokens automatically when the server responds with unauthorized (401) or forbidden (403). 
The token model will be provided in the CredentialsProvider option of the configuration. The token can be stored to disc and be reused in the next request made by the client. When a new token has been retrieved, the client will retry and make the original request again. This behaviour is only for requests made by anonymous users. 401 or 403 responses to logged in users will receive Errors.

To enable this, provide client credentals in the configuration.
```Swift

    class CredentialsManager: CredentialsProvider {
        var credentials: Client.Credentials?

        func provideCredentials() -> Client.Credentials? {
            // credentials can here for example be fetched from keychain 
            return credentials
        }

        func setCredentials(to credentials: Client.Credentials) {
            // credentials can here be saved to for example keychain
            self.credentials = credentials
        }
    }

    let client = Client(Client.Configuration(
        baseURL: URL(string: "https://someapi.com")!, 
        clientCredentials: Client.ClientCredentials(
            clientSecret: "123",
            clientId: "abc"
        ),
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
