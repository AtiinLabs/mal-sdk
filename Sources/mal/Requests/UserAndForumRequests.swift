import Foundation

/// Fetches the signed-in user. `GET /users/@me` (requires a token)
public struct CurrentUserRequest: MALRequest {
    public typealias Response = User

    public let fields: [UserField]

    /// - Parameter fields: Optional fields to return. Defaults to every field.
    public init(fields: [UserField] = UserField.all) {
        self.fields = fields
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/users/@me" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendFields(fields)
        return items
    }
}

/// Fetches the forum's boards. `GET /forum/boards`
public struct ForumBoardsRequest: MALRequest {
    public typealias Response = ForumBoards

    public init() {}

    public var method: HTTPMethod { .get }
    public var path: String { "/forum/boards" }
}

/// Lists forum topics, newest first. `GET /forum/topics`
public struct ForumTopicsRequest: MALRequest {
    public typealias Response = MALPage<ForumTopicSummary>

    public let boardID: Int?
    public let subboardID: Int?
    public let query: String?
    public let topicUserName: String?
    public let userName: String?
    public let limit: Int
    public let offset: Int

    /// - Parameters:
    ///   - boardID: Only topics on this board.
    ///   - subboardID: Only topics on this subboard.
    ///   - query: Search text.
    ///   - topicUserName: Only topics started by this user.
    ///   - userName: Only topics this user posted in.
    ///   - limit: Results per page, 1 to 100.
    ///   - offset: Results to skip.
    public init(boardID: Int? = nil, subboardID: Int? = nil, query: String? = nil, topicUserName: String? = nil, userName: String? = nil, limit: Int = 100, offset: Int = 0) {
        self.boardID = boardID
        self.subboardID = subboardID
        self.query = query
        self.topicUserName = topicUserName
        self.userName = userName
        self.limit = limit
        self.offset = offset
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/forum/topics" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append("board_id", boardID)
        items.append("subboard_id", subboardID)
        items.append("q", query)
        items.append("topic_user_name", topicUserName)
        items.append("user_name", userName)
        items.append("limit", limit)
        items.append("offset", offset)
        return items
    }
}

/// Fetches a forum topic and a page of its posts. `GET /forum/topic/{topic_id}`
public struct ForumTopicRequest: MALRequest {
    public typealias Response = ForumTopicPage

    public let id: Int
    public let limit: Int
    public let offset: Int

    /// - Parameters:
    ///   - id: The topic id.
    ///   - limit: Posts per page, 1 to 100.
    ///   - offset: Posts to skip.
    public init(id: Int, limit: Int = 100, offset: Int = 0) {
        self.id = id
        self.limit = limit
        self.offset = offset
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/forum/topic/\(id)" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append("limit", limit)
        items.append("offset", offset)
        return items
    }
}
