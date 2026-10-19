import XCTest
@testable import mal

internal final class MALClientTests: XCTestCase {
    private let log = RequestLog()

    private func client(token: String? = nil) -> MALClient {
        MALClient(clientID: "client-123", session: MockURLProtocol.session()) { token }
    }

    internal func testSearchSendsClientIDQueryAndEncodedFieldsWithoutToken() async throws {
        MockURLProtocol.respond(status: 200, body: #"{"data":[],"paging":{}}"#, captured: log)

        _ = try await client().execute(MangaSearchRequest(query: "solo leveling", limit: 5, fields: [.title, .authors]))

        let request = try XCTUnwrap(log.last?.request)
        let url = try XCTUnwrap(request.url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(url.path, "/v2/manga")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-MAL-CLIENT-ID"), "client-123")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(formDictionary(url.query), [
            "q": "solo leveling",
            "limit": "5",
            "offset": "0",
            "fields": "title,authors{first_name,last_name}"
        ])
        XCTAssertFalse(try XCTUnwrap(url.query).contains("{"), "Nested field braces must be percent-encoded")
    }

    internal func testTokenAddsBearerAndNSFWIsSentOnlyWhenRequested() async throws {
        MockURLProtocol.respond(status: 200, body: #"{"data":[],"paging":{},"season":{"year":2024,"season":"fall"}}"#, captured: log)

        let page = try await client(token: "user-token").execute(SeasonalAnimeRequest(year: 2024, season: .fall, sort: .score, limit: 500, fields: [.title], includeNSFW: true))

        let request = try XCTUnwrap(log.last?.request)
        XCTAssertEqual(request.url?.path, "/v2/anime/season/2024/fall")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer user-token")
        XCTAssertEqual(formDictionary(request.url?.query), ["sort": "anime_score", "limit": "500", "offset": "0", "fields": "title", "nsfw": "true"])
        XCTAssertEqual(page.season, AnimeSeason(year: 2024, season: .fall))
        XCTAssertTrue(page.data.isEmpty)
    }

    internal func testUpdateSendsOnlyProvidedFieldsAsForm() async throws {
        MockURLProtocol.respond(status: 200, body: #"{"status":"completed","score":8,"num_episodes_watched":12,"is_rewatching":false,"updated_at":"2024-01-02T03:04:05+00:00","start_date":"2023-10"}"#, captured: log)

        let status = try await client(token: "t").execute(UpdateAnimeListStatusRequest(
            animeID: 52991,
            status: .completed,
            isRewatching: false,
            score: 8,
            numWatchedEpisodes: 12,
            tags: ["fantasy", "rewatch soon"],
            startDate: MALDate(year: 2023, month: 10),
            finishDate: MALDate(year: 2024, month: 1, day: 5)
        ))

        let entry = try XCTUnwrap(log.last)
        XCTAssertEqual(entry.request.httpMethod, "PATCH")
        XCTAssertEqual(entry.request.url?.path, "/v2/anime/52991/my_list_status")
        XCTAssertEqual(entry.request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(formDictionary(entry.body), [
            "status": "completed",
            "is_rewatching": "false",
            "score": "8",
            "num_watched_episodes": "12",
            "tags": "fantasy,rewatch soon",
            "start_date": "2023-10",
            "finish_date": "2024-01-05"
        ])
        XCTAssertEqual(status.status, .completed)
        XCTAssertEqual(status.numEpisodesWatched, 12)
        XCTAssertEqual(status.startDate, MALDate(year: 2023, month: 10))
        XCTAssertEqual(status.updatedAt, Date(timeIntervalSince1970: 1_704_164_645))
    }

    internal func testDeleteAcceptsNullBody() async throws {
        MockURLProtocol.respond(status: 200, body: "null", captured: log)

        _ = try await client(token: "t").execute(DeleteMangaListItemRequest(mangaID: 2))

        XCTAssertEqual(log.last?.request.httpMethod, "DELETE")
        XCTAssertEqual(log.last?.request.url?.path, "/v2/manga/2/my_list_status")
    }

    internal func testErrorBodiesMapToTypedErrors() async throws {
        let cases: [ErrorCase] = [
            ErrorCase(status: 404, body: #"{"message":"","error":"not_found"}"#, expected: .httpError(statusCode: 404, error: "not_found", message: "")),
            ErrorCase(status: 401, body: #"{"error":"invalid_token"}"#, expected: .httpError(statusCode: 401, error: "invalid_token", message: nil)),
            ErrorCase(status: 400, body: #"{"message":"invalid q","error":"bad_request"}"#, expected: .httpError(statusCode: 400, error: "bad_request", message: "invalid q")),
            ErrorCase(status: 502, body: "<html>Bad Gateway</html>", expected: .httpError(statusCode: 502, error: nil, message: nil))
        ]

        for testCase in cases {
            MockURLProtocol.respond(status: testCase.status, body: testCase.body)
            do {
                _ = try await client().execute(AnimeDetailsRequest(id: 1))
                XCTFail("Expected HTTP \(testCase.status) to throw")
            } catch let error as MALError {
                XCTAssertEqual(error, testCase.expected)
            }
        }
    }

    private struct ErrorCase {
        let status: Int
        let body: String
        let expected: MALError
    }

    internal func testErrorClassification() {
        XCTAssertTrue(MALError.httpError(statusCode: 404, error: "not_found", message: "").isNotFound)
        XCTAssertTrue(MALError.httpError(statusCode: 401, error: "invalid_token", message: nil).isUnauthorized)
        XCTAssertTrue(MALError.httpError(statusCode: 403, error: "forbidden", message: "").isForbidden)
        XCTAssertFalse(MALError.httpError(statusCode: 400, error: "bad_request", message: "Invalid client id").isForbidden)
        XCTAssertEqual(
            MALError.httpError(statusCode: 400, error: "bad_request", message: "invalid q").localizedDescription,
            "MyAnimeList returned HTTP 400: bad_request: invalid q"
        )
    }

    internal func testRateLimitReadsRetryAfter() async throws {
        MockURLProtocol.respond(status: 429, body: "", headers: ["Retry-After": "30"])

        do {
            _ = try await client().execute(AnimeRankingRequest())
            XCTFail("Expected a rate limit error")
        } catch let error as MALError {
            XCTAssertEqual(error, .rateLimitExceeded(retryAfter: 30))
        }
    }
}
