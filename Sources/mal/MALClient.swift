import Foundation

/// The client for the MyAnimeList API v2 (`https://api.myanimelist.net/v2`).
///
/// Every request sends the `X-MAL-CLIENT-ID` header, which is enough for public data
/// (anime, manga, rankings, seasons, public user lists, forums). Requests for the signed-in
/// user's data (`@me`, suggestions, list updates) also need a token from `tokenProvider`.
public struct MALClient: Sendable {
    private let clientID: String
    private let session: URLSession
    private let tokenProvider: (@Sendable () async throws -> String?)?
    private let baseURL: URL

    /// Creates a client.
    /// - Parameters:
    ///   - clientID: Your MyAnimeList API client ID (myanimelist.net/apiconfig).
    ///   - session: The `URLSession` to use. Defaults to `.shared`.
    ///   - tokenProvider: An optional async closure returning the user's OAuth access token.
    public init(clientID: String, session: URLSession = .shared, tokenProvider: (@Sendable () async throws -> String?)? = nil) {
        self.init(clientID: clientID, session: session, baseURL: MALEndpoints.api, tokenProvider: tokenProvider)
    }

    internal init(clientID: String, session: URLSession, baseURL: URL, tokenProvider: (@Sendable () async throws -> String?)?) {
        self.clientID = clientID
        self.session = session
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
    }

    /// Executes a request.
    /// - Returns: The decoded response.
    /// - Throws: `MALError`.
    public func execute<R: MALRequest>(_ request: R) async throws -> R.Response {
        var urlRequest = try makeURLRequest(request)
        if let token = try await tokenProvider?() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await MALTransport.send(urlRequest, session: session)
        return try MALTransport.decode(R.Response.self, data: data, response: response)
    }

    /// Builds the `URLRequest` for `request` without the `Authorization` header.
    internal func makeURLRequest<R: MALRequest>(_ request: R) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: false) else {
            throw MALError.decodingError("Invalid request path: \(request.path)")
        }
        if !request.queryItems.isEmpty {
            components.percentEncodedQuery = MALTransport.formEncoded(request.queryItems)
        }
        guard let url = components.url else {
            throw MALError.decodingError("Invalid request path: \(request.path)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(clientID, forHTTPHeaderField: "X-MAL-CLIENT-ID")
        if let formFields = request.formFields {
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = Data(MALTransport.formEncoded(formFields).utf8)
        }
        return urlRequest
    }
}

/// MyAnimeList hosts.
internal enum MALEndpoints {
    internal static let api = url("https://api.myanimelist.net/v2")
    internal static let authorize = url("https://myanimelist.net/v1/oauth2/authorize")
    internal static let token = url("https://myanimelist.net/v1/oauth2/token")

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            fatalError("Invalid MyAnimeList URL: \(string)")
        }
        return url
    }
}

/// Sending, error mapping and decoding shared by `MALClient` and `MALOAuth`.
internal enum MALTransport {
    internal static func send(_ request: URLRequest, session: URLSession) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw MALError.networkError(error)
        } catch {
            throw MALError.networkError(URLError(.unknown))
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MALError.httpError(statusCode: 0, error: nil, message: nil)
        }
        return (data, httpResponse)
    }

    internal static func decode<T: Decodable>(_ type: T.Type, data: Data, response: HTTPURLResponse) throws -> T {
        if response.statusCode == 429 {
            throw MALError.rateLimitExceeded(retryAfter: response.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) })
        }
        guard (200...299).contains(response.statusCode) else {
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw MALError.httpError(statusCode: response.statusCode, error: body?.error, message: body?.message)
        }
        // Deletions answer `[]`, `null` or nothing; none of it is meaningful.
        if let empty = MALEmptyResponse() as? T {
            return empty
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MALError.decodingError("Failed to decode \(T.self): \(error)")
        }
    }

    /// The decoder for API responses: snake_case keys and ISO 8601 timestamps.
    internal static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// `application/x-www-form-urlencoded` encoding, also used for query strings.
    internal static func formEncoded(_ items: [URLQueryItem]) -> String {
        items.map { "\(escape($0.name))=\(escape($0.value ?? ""))" }.joined(separator: "&")
    }

    /// RFC 3986 unreserved characters; everything else is percent-encoded.
    private static let unreserved = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

    private static func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: unreserved) ?? string
    }

    private struct ErrorBody: Decodable {
        let error: String?
        let message: String?
    }
}
