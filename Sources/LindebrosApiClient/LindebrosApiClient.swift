import Foundation

/// Use this client when you want to communicate with APIs
public struct LindebrosApiClient {
    /// The baseUrl to the API
    var baseURL: String

    private var logger: Logger

    public init(baseURL: String, logLevel: LogLevel = .none) {
        self.baseURL = baseURL

        logger = Logger(logLevel: logLevel)
    }
}

// MARK: Public methods

public extension LindebrosApiClient {
    /**
     Makes a request to the API.

     - parameter r: The request object that describes the API request
     - parameter completionHandler: The callback method to be invoked when the request is completed
     */
    func call<Model: Decodable, ErrorModel: ErrorResponse, RequestBodyModel: Encodable>(
        _ r: Request<Model, ErrorModel, RequestBodyModel>,
        bearerToken: String,
        completionHandler: @escaping (_ result: ApiResponse<Model, ErrorModel>) -> Void
    ) {
        let session = URLSession.shared
        let endpointUrlStr = "\(r.isRelativeUrl ? baseURL : "")\(r.endpoint)"
        guard let endpointUrl = URL(string: endpointUrlStr) else {
            completionHandler(
                ApiResponse(isOk: false, status: HTTPStatusCode.badRequest, data: nil, error: nil)
            )
            return
        }
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = r.method.rawValue
        request.timeoutInterval = 6
        request.addValue(r.contentType.header, forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + bearerToken, forHTTPHeaderField: "Authorization")

        if let customHeaders = r.customHeaders {
            customHeaders.forEach { customHeader in
                request.addValue(customHeader.value, forHTTPHeaderField: customHeader.key)
            }
        }

        if let body = r.body {
            request.httpBody = body
            request.addValue(String(body.count), forHTTPHeaderField: "content-length")
        }

        let requestStr = "[\(r.method.rawValue)] \(endpointUrlStr) \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")"
        logger.info(requestStr)

        let task = session.dataTask(with: request, completionHandler: { data, response, requestError in
            let response = response as? HTTPURLResponse
            let httpStatus: HTTPStatusCode = HTTPStatusCode(rawValue: response?.statusCode ?? 0) ?? .unknown

            var model: Model?

            var errorModel: ErrorModel?

            var errors: [Error] = []
            if let error = requestError {
                errors.append(error)
            }

            var isOk = httpStatus.isOk()
            if let data = data, data.count > 0 {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    if httpStatus.isOk() {
                        model = try jsonDecoder.decode(Model.self, from: data)
                    } else {
                        errorModel = try jsonDecoder.decode(ErrorModel.self, from: data)
                    }
                } catch let e {
                    // Logger.error("\(endpointUrlStr): Could not convert model \(e)")
                    isOk = false
                    errors.append(e)
                }
            }

            if errors.count > 0 {
                errors.forEach { e in
                    logger.error("\(e)")
                }

                errorModel = ErrorMessage(message: errors.first?.localizedDescription) as? ErrorModel
            }

            let responseObject = ApiResponse(isOk: isOk, status: httpStatus, data: model, errorModel: errorModel, error: errors)

            logger.info("\(r.endpoint) \(errors.count == 0 ? responseObject.status.getEmoj() : "⚠️") \(responseObject.status.rawValue) \(!responseObject.isOk ? String(data: data ?? Data(), encoding: .utf8) ?? "" : r.debugData ? String(data: data ?? Data(), encoding: .utf8) ?? "" : "")")

            // We will continue to work on a background thread and let ApiClient switch back to the main thread.
            DispatchQueue.main.async {
                completionHandler(responseObject)
            }
        })

        task.resume()
    }
}
