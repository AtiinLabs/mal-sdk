import Foundation

/// MyAnimeList's OAuth 2.0 authorization code flow with PKCE.
///
/// 1. Open `authorizationRequest().url` in a browser session (for example
///    `ASWebAuthenticationSession`) and keep the returned request.
/// 2. Pass the callback URL to `authorizationCode(from:matching:)`.
/// 3. Exchange the code with `exchangeCode(_:for:)`, store the `MALToken`, and send
///    `accessToken` through `MALClient`'s `tokenProvider`.
/// 4. Before `expiresAt`, or after a 401, call `refresh(_:)`.
///
/// MyAnimeList only supports the `plain` PKCE method, so the code challenge equals the verifier.
public struct MALOAuth: Sendable {
    private let clientID: String
    private let clientSecret: String?
    private let redirectURI: String?
    private let session: URLSession
    private let tokenURL: URL

    /// - Parameters:
    ///   - clientID: Your MyAnimeList API client ID.
    ///   - clientSecret: The client secret of "Web" apps; `nil` for "iOS", "Android" and "Other" apps.
    ///   - redirectURI: The redirect URL registered for the app. Required when the app registers several.
    ///   - session: The `URLSession` for token requests.
    public init(clientID: String, clientSecret: String? = nil, redirectURI: String? = nil, session: URLSession = .shared) {
        self.init(clientID: clientID, clientSecret: clientSecret, redirectURI: redirectURI, session: session, tokenURL: MALEndpoints.token)
    }

    internal init(clientID: String, clientSecret: String?, redirectURI: String?, session: URLSession, tokenURL: URL) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.session = session
        self.tokenURL = tokenURL
    }

    /// Creates the URL to sign in with, with a fresh code verifier and state.
    public func authorizationRequest() -> MALAuthorizationRequest {
        let codeVerifier = Self.randomString(length: 128)
        let state = Self.randomString(length: 32)
        var components = URLComponents(url: MALEndpoints.authorize, resolvingAgainstBaseURL: false)
        var items = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code_challenge", value: codeVerifier),
            URLQueryItem(name: "code_challenge_method", value: "plain"),
            URLQueryItem(name: "state", value: state)
        ]
        items.append("redirect_uri", redirectURI)
        components?.percentEncodedQuery = MALTransport.formEncoded(items)
        return MALAuthorizationRequest(url: components?.url ?? MALEndpoints.authorize, codeVerifier: codeVerifier, state: state)
    }

    /// Reads the authorization code from the redirect MyAnimeList sent the browser to.
    /// - Throws: `MALError.invalidCallback` when the user denied access, the state does not match, or no code is present.
    public func authorizationCode(from callbackURL: URL, matching request: MALAuthorizationRequest) throws -> String {
        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value }
        if let error = value("error") {
            throw MALError.invalidCallback("MyAnimeList authorization failed: \(value("message") ?? error)")
        }
        guard value("state") == request.state else {
            throw MALError.invalidCallback("The callback state does not match the authorization request.")
        }
        guard let code = value("code"), !code.isEmpty else {
            throw MALError.invalidCallback("The callback has no authorization code.")
        }
        return code
    }

    /// Exchanges an authorization code for tokens.
    public func exchangeCode(_ code: String, for request: MALAuthorizationRequest) async throws -> MALToken {
        var items = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: request.codeVerifier)
        ]
        items.append("redirect_uri", redirectURI)
        return try await requestToken(items)
    }

    /// Exchanges a refresh token for new tokens. Store the result in place of the old token;
    /// MyAnimeList issues a new refresh token each time.
    public func refresh(_ token: MALToken) async throws -> MALToken {
        try await requestToken([
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: token.refreshToken)
        ])
    }

    private func requestToken(_ grantItems: [URLQueryItem]) async throws -> MALToken {
        var items = [URLQueryItem(name: "client_id", value: clientID)]
        items.append("client_secret", clientSecret)
        items += grantItems

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(MALTransport.formEncoded(items).utf8)

        let (data, response) = try await MALTransport.send(request, session: session)
        let tokenResponse = try MALTransport.decode(TokenResponse.self, data: data, response: response)
        return MALToken(
            tokenType: tokenResponse.tokenType,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn,
            issuedAt: Date()
        )
    }

    /// A random string of RFC 7636 code verifier characters, from the system's secure generator.
    internal static func randomString(length: Int) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in characters[Int.random(in: 0..<characters.count, using: &generator)] })
    }

    private struct TokenResponse: Decodable {
        let tokenType: String
        let expiresIn: Int
        let accessToken: String
        let refreshToken: String
    }
}

/// An in-progress sign-in: the URL to open and the values needed to finish it.
public struct MALAuthorizationRequest: Codable, Hashable, Sendable {
    /// The MyAnimeList sign-in URL.
    public let url: URL
    /// The PKCE code verifier; sent again when exchanging the code.
    public let codeVerifier: String
    /// The state the callback must echo.
    public let state: String
}

/// OAuth tokens for a signed-in user. `Codable` so apps can store it (for example in the Keychain).
public struct MALToken: Codable, Hashable, Sendable {
    /// Always `Bearer`.
    public let tokenType: String
    public let accessToken: String
    public let refreshToken: String
    /// Access token lifetime in seconds, as issued.
    public let expiresIn: Int
    /// When the token was received.
    public let issuedAt: Date

    public init(tokenType: String = "Bearer", accessToken: String, refreshToken: String, expiresIn: Int, issuedAt: Date) {
        self.tokenType = tokenType
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.issuedAt = issuedAt
    }

    /// When the access token stops working.
    public var expiresAt: Date {
        issuedAt.addingTimeInterval(TimeInterval(expiresIn))
    }

    /// Whether the access token expires within `leeway` seconds of `date`.
    public func isExpired(at date: Date = Date(), leeway: TimeInterval = 60) -> Bool {
        date.addingTimeInterval(leeway) >= expiresAt
    }
}
