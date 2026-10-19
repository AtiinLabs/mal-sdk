import Foundation

/// The HTTP method of a MyAnimeList API request.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A single MyAnimeList API v2 request.
public protocol MALRequest: Sendable {
    /// The decoded response type.
    associatedtype Response: Decodable & Sendable

    /// The HTTP method.
    var method: HTTPMethod { get }

    /// The path below `https://api.myanimelist.net/v2`, starting with `/`.
    var path: String { get }

    /// Query parameters. `nil` values are not sent.
    var queryItems: [URLQueryItem] { get }

    /// Form fields sent as `application/x-www-form-urlencoded`, or `nil` for no body.
    var formFields: [URLQueryItem]? { get }
}

public extension MALRequest {
    /// Requests send no query parameters by default.
    var queryItems: [URLQueryItem] { [] }

    /// Requests send no body by default.
    var formFields: [URLQueryItem]? { nil }
}

/// The response of endpoints that return no meaningful body, such as deletions.
public struct MALEmptyResponse: Decodable, Equatable, Sendable {
    public init() {}

    public init(from decoder: Decoder) throws {
        self.init()
    }
}

internal extension Array where Element == URLQueryItem {
    /// Appends a query item when `value` is non-nil.
    mutating func append(_ name: String, _ value: String?) {
        if let value {
            append(URLQueryItem(name: name, value: value))
        }
    }

    /// Appends a query item when `value` is non-nil.
    mutating func append(_ name: String, _ value: Int?) {
        append(name, value.map(String.init))
    }

    /// Appends a query item when `value` is non-nil.
    mutating func append(_ name: String, _ value: Bool?) { // swiftlint:disable:this discouraged_optional_boolean
        append(name, value.map { $0 ? "true" : "false" })
    }

    /// Appends a comma-separated `fields` item when `fields` is non-empty.
    mutating func appendFields<F: MALField>(_ fields: [F]) {
        if !fields.isEmpty {
            append(URLQueryItem(name: "fields", value: fields.map(\.rawValue).joined(separator: ",")))
        }
    }
}
