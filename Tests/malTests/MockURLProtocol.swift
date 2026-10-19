import Foundation
import XCTest

internal final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) internal static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override internal static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override internal static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override internal func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override internal func stopLoading() {}

    /// A session whose requests go to `requestHandler`.
    internal static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Answers every request with `status` and `body`, recording the requests in `captured`.
    internal static func respond(status: Int, body: String, headers: [String: String] = [:], captured: RequestLog? = nil) {
        requestHandler = { request in
            captured?.append(request)
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers))
            return (response, Data(body.utf8))
        }
    }
}

/// Requests seen by `MockURLProtocol`. The body is read from the stream URLSession hands the protocol.
internal final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [(request: URLRequest, body: String)] = []

    internal var last: (request: URLRequest, body: String)? {
        lock.withLock { storage.last }
    }

    internal func append(_ request: URLRequest) {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data()
        lock.withLock { storage.append((request, String(bytes: body, encoding: .utf8) ?? "")) }
    }

    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}

/// Splits a form or query string into a dictionary, percent-decoding names and values.
internal func formDictionary(_ string: String?) -> [String: String] {
    var result: [String: String] = [:]
    for pair in (string ?? "").split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1).map { String($0).removingPercentEncoding ?? String($0) }
        result[parts[0]] = parts.count > 1 ? parts[1] : ""
    }
    return result
}
