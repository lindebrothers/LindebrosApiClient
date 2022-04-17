import Foundation

public struct QuerystringState: Hashable {
    public init(keyValues: [String: Set<String>] = [:]) {
        self.keyValues = keyValues
    }

    /// This property holds the selected state. The key represents the queryKey and its multiple values.
    public var keyValues: [String: Set<String>] = [:]
}

extension QuerystringState: Equatable {
    public static func == (lhs: QuerystringState, rhs: QuerystringState) -> Bool {
        return lhs.keyValues == rhs.keyValues
    }
}

// MARK: Public methods

public extension QuerystringState {
    /**
     Create a QuerystringState based on a querystring
     - parameter queryString: the queryString to extract values from
     */
    init(queryString: String) {
        var dictionary: [String: Set<String>] = [:]
        let queries = queryString.components(separatedBy: "&")
        for query in queries {
            let keyValue = query.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = Self.trimValue(keyValue[1])

                if var currentValue = dictionary[key] {
                    currentValue.insert(value)
                    dictionary[key] = currentValue
                } else {
                    var newSet: Set<String> = []
                    newSet.insert(value)
                    dictionary[key] = newSet
                }
            }
        }
        keyValues = dictionary
    }

    /**
     Convenient getter for a specific key that also can provide a default value if the key does not exist
     - parameter key: The key identifier
     */
    func get(_ key: String) -> Set<String>? {
        return keyValues[key]
    }

    /**
     Convenient setter for a keyValue and return a cloned state
     - parameter key: The key identifier
     - parameter value: The new value
     - returns a new QuerystringState
     */
    func set(_ key: String, value: Set<String>) -> QuerystringState {
        return clone(overwriteWith: [key: value])
    }

    /**
     Removes a value from a key
     - parameter key: The key to remove the value from
     - parameter value: The value to search for and to remove
     - returns a new QuerystringState
     */
    func removeValueFromKey(_ key: String, value: String) -> QuerystringState {
        if let values = get(key) {
            return clone(overwriteWith: [key: values.filter { $0 != value }])
        }
        return self
    }

    /**
     returns a modified instance of QuerystringState
     - parameter overwriteWith: override params in the current state
     - parameter exclude: exlude potential existing keys in the current state
     - returns a new instance of the QuerystringState
     */
    func clone(overwriteWith newValues: [String: Set<String>] = [:], exclude: [String] = []) -> QuerystringState {
        var keyValues = self.keyValues.filter { !exclude.contains($0.key) }

        // We don't want to store any empty strings at all. Empty string is no selection.
        for (key, value) in newValues {
            let filteredValues = value.filter { !$0.isEmpty }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if !filteredValues.isEmpty {
                keyValues[key] = Set(filteredValues)
            } else {
                // remove the key if it is empty
                keyValues.removeValue(forKey: key)
            }
        }

        // sort the values to make em testable

        return QuerystringState(keyValues: keyValues)
    }

    var exludeInternals: QuerystringState {
        QuerystringState(keyValues: keyValues.filter { $0.key.contains("_") == false })
    }

    /**
     Querystring representation of the state.
     */
    var asQueryString: String {
        let output = keyValues.sorted { ($0.key < $1.key) }.map { Self.queryStringItems(key: $0.key, value: $0.value) }.flatMap { $0 }
        return output.joined(separator: "&")
    }
}

// MARK: Static functions

private extension QuerystringState {
    /**
     Removes any unwanted values

     - parameter with value: the value to trim
     - returns a trimmed value excluded from unwanted values
     */
    static func trimValue(_ value: String) -> String {
        if let decodedValue = value.removingPercentEncoding {
            return decodedValue.replacingOccurrences(of: "+", with: " ")
        }

        return value
    }

    /**
     Builds up an array representation of Keyvalues  according to following template ["key=value"].
     Example: ["someKey": [1, 2]] >> ["someKey=1", "someKey=2"]

     - parameter key: The identifier of the key
     - parameter value: is either a string or an array or Strings. Other types will be ignored
     - returns an array according to the template ["key=value"]
     */
    static func queryStringItems(key: String, value: Any) -> [String] {
        var strings = [String]()

        switch value {
        case let items as Set<String>:
            for item in items.sorted(by: { ($0 < $1) }) {
                strings.append(contentsOf: Self.queryStringItems(key: key, value: item))
            }
        default:
            if let escaped = "\(value)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                strings.append("\(key)=\(escaped)")
            }
        }
        return strings
    }
}
