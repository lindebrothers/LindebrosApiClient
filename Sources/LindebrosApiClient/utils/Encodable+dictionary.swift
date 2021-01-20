import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }

    var asQueryString: String {
        do {
            return try asDictionary().queryString
        } catch {
            return ""
        }
    }

    var asRawQueryString: String {
        do {
            return try asDictionary().rawQueryString
        } catch {
            return ""
        }
    }
}

extension Dictionary {
    private func convertToQueryStringArray(key: String, value: Any, doPerentageEncoding: Bool = true) -> [String] {
        var strings = [String]()

        switch value {
        case let items as [Any]:
            for item in items {
                strings.append(contentsOf: convertToQueryStringArray(key: key, value: item, doPerentageEncoding: doPerentageEncoding))
            }
        default:
            if let escaped = "\(value)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                strings.append("\(key)=\(doPerentageEncoding ? escaped : "\(value)")")
            }
        }
        return strings
    }

    var queryString: String {
        var output = [String]()

        forEach { key, value in
            if let key = key as? String {
                output.append(contentsOf: convertToQueryStringArray(key: key, value: value))
            }
        }

        return output.joined(separator: "&")
    }

    var rawQueryString: String {
        var output = [String]()

        forEach { key, value in
            if let key = key as? String {
                output.append(contentsOf: convertToQueryStringArray(key: key, value: value, doPerentageEncoding: false))
            }
        }

        return output.joined(separator: "&")
    }
}
