# LindebrosApiClient
LindebrosApiClient is a client written in Swift. It is a `URLSession` implementation that makes it easy and convenient to make requests to a backend server.


## Get Started
1. Install the client using the Swift Package Manager.
    ```Swift
    dependencies: [
        .package(url: "https://github.com/lindebrothers/LindebrosApiClient.git", .upToNextMajor(from: "1.0.0"))
    ]
    ```

2. Include the The client where you want to use it in your project: Example.
    ``` Swift
    import LindebrosApiClient

    class SomeClass {
        func fetch() {
            let client = LindebrosApiClient(
                baseURL: "http://localhost",
                logLevel: .debug
            )
        }
    }
    ```
3. Create a response model and a request model.
    ``` Swift
    import LindebrosApiClient

    struct Response: Decodable {
       var someProperty: String
    }

    struct Body: Encodable {
       var name: String
       var title: String
    }

    class SomeClass {
        func fetch(bearerToken: String) {
            let client = LindebrosApiClient(
              baseURL: "http:localhost",
              logLevel: .debug
            )

            let request = RequestModel<Response, Body, ErrorResonse>(
              endpoint: "/some/endpoint",
              method: .post,
              data: Body(name: "Awesome", title: "Boss")
            )

            client.call(
              request,
              bearerToken: bearerToken
            ) { response in
              if response.isOk {
                print(response.someProperty)
              }
            }
        }
    }
   ```




A description of this package.
