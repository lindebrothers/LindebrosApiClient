import Foundation

/// The Http method to use in the request
public enum HttpMethod: String {
    /// The ApiClient makes a GET request without a body in the request
    case get = "GET"

    /// The ApiClient makes a POST request with a body containg data to be sent to the API
    case post = "POST"

    /// The ApiClient makes a PUT request with a body containg data to be sent to the API
    case put = "PUT"

    /// The ApiClient makes a DELETE request with a body containg data to be sent to the API
    case delete = "DELETE"
}
