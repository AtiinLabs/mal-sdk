import XCTest
@testable import mal

internal final class MALOAuthTests: XCTestCase {
    private let log = RequestLog()

    private func oauth(clientSecret: String? = nil, redirectURI: String? = nil) -> MALOAuth {
        MALOAuth(clientID: "client-123", clientSecret: clientSecret, redirectURI: redirectURI, session: MockURLProtocol.session())
    }

    internal func testAuthorizationURLUsesPlainPKCEAndFreshState() throws {
        let first = oauth(redirectURI: "ito://mal-callback").authorizationRequest()
        let second = oauth().authorizationRequest()

        let query = formDictionary(first.url.query)
        XCTAssertEqual(first.url.host, "myanimelist.net")
        XCTAssertEqual(first.url.path, "/v1/oauth2/authorize")
        XCTAssertEqual(query["response_type"], "code")
        XCTAssertEqual(query["client_id"], "client-123")
        XCTAssertEqual(query["code_challenge"], first.codeVerifier)
        XCTAssertEqual(query["code_challenge_method"], "plain")
        XCTAssertEqual(query["state"], first.state)
        XCTAssertEqual(query["redirect_uri"], "ito://mal-callback")
        XCTAssertEqual(first.codeVerifier.count, 128)
        XCTAssertTrue(first.codeVerifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-._~".contains($0)) })
        XCTAssertNil(formDictionary(second.url.query)["redirect_uri"])
        XCTAssertNotEqual(first.codeVerifier, second.codeVerifier)
        XCTAssertNotEqual(first.state, second.state)
    }

    internal func testCallbackReturnsCodeOnlyForMatchingState() throws {
        let request = oauth().authorizationRequest()
        let client = oauth()

        let code = try client.authorizationCode(from: try XCTUnwrap(URL(string: "ito://mal-callback?code=abc&state=\(request.state)")), matching: request)
        XCTAssertEqual(code, "abc")

        XCTAssertThrowsError(try client.authorizationCode(from: try XCTUnwrap(URL(string: "ito://mal-callback?code=abc&state=forged")), matching: request))
        XCTAssertThrowsError(try client.authorizationCode(from: try XCTUnwrap(URL(string: "ito://mal-callback?state=\(request.state)")), matching: request))
        XCTAssertThrowsError(try client.authorizationCode(from: try XCTUnwrap(URL(string: "ito://mal-callback?error=access_denied&state=\(request.state)")), matching: request)) { error in
            XCTAssertEqual(error as? MALError, .invalidCallback("MyAnimeList authorization failed: access_denied"))
        }
    }

    internal func testCodeExchangeSendsVerifierAndOmitsMissingSecret() async throws {
        MockURLProtocol.respond(status: 200, body: #"{"token_type":"Bearer","expires_in":2678400,"access_token":"access","refresh_token":"refresh"}"#, captured: log)
        let client = oauth()
        let request = client.authorizationRequest()
        let before = Date()

        let token = try await client.exchangeCode("the-code", for: request)

        let sent = try XCTUnwrap(log.last)
        XCTAssertEqual(sent.request.url?.absoluteString, "https://myanimelist.net/v1/oauth2/token")
        XCTAssertEqual(sent.request.httpMethod, "POST")
        XCTAssertEqual(formDictionary(sent.body), [
            "client_id": "client-123",
            "grant_type": "authorization_code",
            "code": "the-code",
            "code_verifier": request.codeVerifier
        ])
        XCTAssertEqual(token.accessToken, "access")
        XCTAssertEqual(token.refreshToken, "refresh")
        XCTAssertGreaterThanOrEqual(token.expiresAt.timeIntervalSince(before), 2_678_400)
        XCTAssertFalse(token.isExpired())
    }

    internal func testRefreshSendsSecretWhenConfigured() async throws {
        MockURLProtocol.respond(status: 200, body: #"{"token_type":"Bearer","expires_in":3600,"access_token":"new","refresh_token":"new-refresh"}"#, captured: log)
        let old = MALToken(accessToken: "old", refreshToken: "old-refresh", expiresIn: 3600, issuedAt: Date(timeIntervalSince1970: 0))

        let token = try await oauth(clientSecret: "secret").refresh(old)

        XCTAssertEqual(formDictionary(log.last?.body), [
            "client_id": "client-123",
            "client_secret": "secret",
            "grant_type": "refresh_token",
            "refresh_token": "old-refresh"
        ])
        XCTAssertEqual(token.refreshToken, "new-refresh")
        XCTAssertTrue(old.isExpired())
    }

    internal func testRejectedRefreshSurfacesMyAnimeListMessage() async throws {
        MockURLProtocol.respond(status: 401, body: #"{"error":"invalid_request","message":"The refresh token is invalid.","hint":"Cannot decrypt the refresh token"}"#)
        let old = MALToken(accessToken: "old", refreshToken: "bogus", expiresIn: 1, issuedAt: Date())

        do {
            _ = try await oauth().refresh(old)
            XCTFail("Expected the refresh to fail")
        } catch let error as MALError {
            XCTAssertTrue(error.isUnauthorized)
            XCTAssertEqual(error.localizedDescription, "MyAnimeList returned HTTP 401: invalid_request: The refresh token is invalid.")
        }
    }

    internal func testTokenExpiryUsesLeeway() {
        let issued = Date(timeIntervalSince1970: 1_000)
        let token = MALToken(accessToken: "a", refreshToken: "r", expiresIn: 3_600, issuedAt: issued)

        XCTAssertFalse(token.isExpired(at: issued.addingTimeInterval(3_500)))
        XCTAssertTrue(token.isExpired(at: issued.addingTimeInterval(3_550)))
        XCTAssertTrue(token.isExpired(at: issued.addingTimeInterval(3_600), leeway: 0))
    }
}
