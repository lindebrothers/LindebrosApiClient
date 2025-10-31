import Foundation

public extension Client {
    struct Configuration: Sendable {
        public init(
            baseURL: URL,
            credentialsProvider: CredentialsProvider? = nil,
            urlSession: URLSessionProvider = URLSession.shared,
            encodingConfig: [EncodingConfigType] = [
                .nonConformingFloatStrategy(.convertToString(
                    positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "Nan"
                )),
                .keyEncodingStrategy(.useDefaultKeys),
                .dateEncodingStrategy(.iso8601)
            ],
            decodingConfig: [DecodingConfigType] = [
                .nonConformingFloatStrategy(.convertFromString(
                    positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "Nan"
                )),
                .keydecodingStrategy(.useDefaultKeys),
                .dateDecodingStrategy(.deferredToDate)
            ],
            timeout: TimeInterval? = nil,
            logger: ApiLogger? = nil,
            loggingStrategy: LoggingStrategy = .normal
        ) {
            self.baseURL = baseURL
            self.urlSession = urlSession
            self.credentialsProvider = credentialsProvider
            self.timeout = timeout
            self.logger = logger
            self.encodingConfig = encodingConfig
            self.decodingConfig = decodingConfig
            self.loggingStrategy = loggingStrategy
        }

        public let baseURL: URL
        public let credentialsProvider: CredentialsProvider?
        public let urlSession: URLSessionProvider
        public let encodingConfig: [EncodingConfigType]
        public let decodingConfig: [DecodingConfigType]
        public let timeout: TimeInterval?
        public let loggingStrategy: LoggingStrategy

        let logger: ApiLogger?
    }

    enum EncodingConfigType: Sendable {
        case contentType(Client.ContentType)
        case keyEncodingStrategy(JSONEncoder.KeyEncodingStrategy)
        case dateEncodingStrategy(JSONEncoder.DateEncodingStrategy)
        case nonConformingFloatStrategy(JSONEncoder.NonConformingFloatEncodingStrategy)

        var isContentType: Bool {
            if case .contentType = self {
                return true
            }
            return false
        }

        func populateValues(to encoder: JSONEncoder) {
            switch self {
            case let .keyEncodingStrategy(value):
                encoder.keyEncodingStrategy = value
            case let .dateEncodingStrategy(value):
                encoder.dateEncodingStrategy = value
            case let .nonConformingFloatStrategy(value):
                encoder.nonConformingFloatEncodingStrategy = value
            case .contentType:
                break
            }
        }

        var contentType: Client.ContentType? {
            if case let .contentType(type) = self {
                return type
            }
            return nil
        }
    }

    enum DecodingConfigType: Sendable {
        case keydecodingStrategy(JSONDecoder.KeyDecodingStrategy)
        case dateDecodingStrategy(JSONDecoder.DateDecodingStrategy)
        case nonConformingFloatStrategy(JSONDecoder.NonConformingFloatDecodingStrategy)
        func populateValues(to decoder: JSONDecoder) {
            switch self {
            case let .keydecodingStrategy(value):
                decoder.keyDecodingStrategy = value
            case let .dateDecodingStrategy(value):
                decoder.dateDecodingStrategy = value
            case let .nonConformingFloatStrategy(value):
                decoder.nonConformingFloatDecodingStrategy = value
            }
        }
    }

    
}
