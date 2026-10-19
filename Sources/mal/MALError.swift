import Foundation

/// Errors thrown by `MALClient` and `MALOAuth`.
public enum MALError: Error, Equatable, Sendable {
    /// The request could not reach the server (e.g., no internet connection).
    case networkError(URLError)

    /// The server returned a non-2xx status. `error` and `message` come from
    /// MyAnimeList's error body (`{"error": "not_found", "message": ""}`) when present.
    case httpError(statusCode: Int, error: String?, message: String?)

    /// HTTP 429. `retryAfter` is the `Retry-After` header in seconds, when sent.
    case rateLimitExceeded(retryAfter: Int?)

    /// The request or response could not be encoded or decoded.
    case decodingError(String)

    /// The OAuth callback URL did not carry a usable authorization code.
    case invalidCallback(String)
}

public extension MALError {
    /// The HTTP status code, when the server answered.
    var statusCode: Int? {
        switch self {
        case .httpError(let statusCode, _, _):
            return statusCode

        case .rateLimitExceeded:
            return 429

        default:
            return nil
        }
    }

    /// Whether MyAnimeList answered 404: the anime, manga, user, season or list item does not exist.
    var isNotFound: Bool {
        statusCode == 404
    }

    /// Whether the access token is missing, invalid or expired (HTTP 401). Refresh the token or sign in again.
    var isUnauthorized: Bool {
        statusCode == 401
    }

    /// Whether MyAnimeList refused the request (HTTP 403): no client ID was sent, or it detected
    /// too many requests from this client. An invalid client ID is a 400.
    var isForbidden: Bool {
        statusCode == 403
    }
}

extension MALError: LocalizedError {
    /// A readable description using MyAnimeList's error code and message when available.
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return error.localizedDescription

        case let .httpError(statusCode, error, message):
            let detail = [error, message].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ": ")
            return detail.isEmpty ? "MyAnimeList returned HTTP \(statusCode)." : "MyAnimeList returned HTTP \(statusCode): \(detail)"

        case .rateLimitExceeded(let retryAfter):
            if let retryAfter {
                return "MyAnimeList rate limit exceeded. Retry after \(retryAfter) seconds."
            }
            return "MyAnimeList rate limit exceeded."

        case .decodingError(let message):
            return message

        case .invalidCallback(let message):
            return message
        }
    }
}
