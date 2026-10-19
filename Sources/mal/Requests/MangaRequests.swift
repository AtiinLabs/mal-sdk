import Foundation

/// Searches manga by title. `GET /manga`
///
/// MyAnimeList rejects queries shorter than 3 characters with HTTP 400 (`invalid q`).
public struct MangaSearchRequest: MALRequest {
    public typealias Response = MALPage<MALNode<Manga>>

    public let query: String
    public let limit: Int
    public let offset: Int
    public let fields: [MangaField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - query: Search text, 3 or more characters.
    ///   - limit: Results per page, 1 to 100.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(query: String, limit: Int = 100, offset: Int = 0, fields: [MangaField] = MangaField.list, includeNSFW: Bool = false) {
        self.query = query
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/manga" }

    public var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "q", value: query)]
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Fetches one manga. `GET /manga/{manga_id}`
public struct MangaDetailsRequest: MALRequest {
    public typealias Response = Manga

    public let id: Int
    public let fields: [MangaField]

    /// - Parameters:
    ///   - id: The MyAnimeList manga id.
    ///   - fields: Fields to return. Defaults to every field.
    public init(id: Int, fields: [MangaField] = MangaField.details) {
        self.id = id
        self.fields = fields
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/manga/\(id)" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendFields(fields)
        return items
    }
}

/// Fetches a manga ranking. `GET /manga/ranking`
public struct MangaRankingRequest: MALRequest {
    public typealias Response = MALPage<MALRankedNode<Manga>>

    public let type: MangaRankingType
    public let limit: Int
    public let offset: Int
    public let fields: [MangaField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - type: The ranking.
    ///   - limit: Results per page, 1 to 500.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(type: MangaRankingType = .all, limit: Int = 100, offset: Int = 0, fields: [MangaField] = MangaField.list, includeNSFW: Bool = false) {
        self.type = type
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/manga/ranking" }

    public var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "ranking_type", value: type.rawValue)]
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Fetches a user's manga list. `GET /users/{user_name}/mangalist`
///
/// MyAnimeList answers 404 for unknown users.
public struct UserMangaListRequest: MALRequest {
    public typealias Response = MALPage<MangaListEntry>

    public let userName: String
    public let status: MangaReadStatus?
    public let sort: UserMangaListSort?
    public let limit: Int
    public let offset: Int
    public let fields: [MangaField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - userName: The user name, or `@me` for the signed-in user (requires a token).
    ///   - status: Only entries with this status; every entry when `nil`.
    ///   - sort: Sort order; MyAnimeList's default when `nil`.
    ///   - limit: Results per page, 1 to 1000.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to the full list entry plus every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(
        userName: String = "@me",
        status: MangaReadStatus? = nil,
        sort: UserMangaListSort? = nil,
        limit: Int = 1000,
        offset: Int = 0,
        fields: [MangaField] = [.listStatusAll] + MangaField.list.filter { $0 != .myListStatus },
        includeNSFW: Bool = false
    ) {
        self.userName = userName
        self.status = status
        self.sort = sort
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/users/\(userName)/mangalist" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append("status", status?.rawValue)
        items.append("sort", sort?.rawValue)
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Adds a manga to the signed-in user's list or updates its entry.
/// `PATCH /manga/{manga_id}/my_list_status` (requires a token)
///
/// Only non-`nil` fields are sent; other fields keep their values.
public struct UpdateMangaListStatusRequest: MALRequest {
    public typealias Response = MangaListStatus

    public let mangaID: Int
    public let status: MangaReadStatus?
    // swiftlint:disable:next discouraged_optional_boolean
    public let isRereading: Bool?
    public let score: Int?
    public let numVolumesRead: Int?
    public let numChaptersRead: Int?
    public let priority: Int?
    public let numTimesReread: Int?
    public let rereadValue: Int?
    public let tags: [String]?
    public let comments: String?
    public let startDate: MALDate?
    public let finishDate: MALDate?

    /// - Parameters:
    ///   - mangaID: The MyAnimeList manga id.
    ///   - status: The list status.
    ///   - isRereading: Rereading after completion.
    ///   - score: 0 (unscored) to 10.
    ///   - numVolumesRead: Volumes read.
    ///   - numChaptersRead: Chapters read.
    ///   - priority: 0 (low) to 2 (high).
    ///   - numTimesReread: Completed rereads.
    ///   - rereadValue: 0 to 5.
    ///   - tags: Tags; replaces existing tags.
    ///   - comments: Notes.
    ///   - startDate: When the user started.
    ///   - finishDate: When the user finished.
    public init(
        mangaID: Int,
        status: MangaReadStatus? = nil,
        // swiftlint:disable:next discouraged_optional_boolean
        isRereading: Bool? = nil,
        score: Int? = nil,
        numVolumesRead: Int? = nil,
        numChaptersRead: Int? = nil,
        priority: Int? = nil,
        numTimesReread: Int? = nil,
        rereadValue: Int? = nil,
        tags: [String]? = nil,
        comments: String? = nil,
        startDate: MALDate? = nil,
        finishDate: MALDate? = nil
    ) {
        self.mangaID = mangaID
        self.status = status
        self.isRereading = isRereading
        self.score = score
        self.numVolumesRead = numVolumesRead
        self.numChaptersRead = numChaptersRead
        self.priority = priority
        self.numTimesReread = numTimesReread
        self.rereadValue = rereadValue
        self.tags = tags
        self.comments = comments
        self.startDate = startDate
        self.finishDate = finishDate
    }

    public var method: HTTPMethod { .patch }
    public var path: String { "/manga/\(mangaID)/my_list_status" }

    public var formFields: [URLQueryItem]? {
        var items: [URLQueryItem] = []
        items.append("status", status?.rawValue)
        items.append("is_rereading", isRereading)
        items.append("score", score)
        items.append("num_volumes_read", numVolumesRead)
        items.append("num_chapters_read", numChaptersRead)
        items.append("priority", priority)
        items.append("num_times_reread", numTimesReread)
        items.append("reread_value", rereadValue)
        items.append("tags", tags?.joined(separator: ","))
        items.append("comments", comments)
        items.append("start_date", startDate?.description)
        items.append("finish_date", finishDate?.description)
        return items
    }
}

/// Removes a manga from the signed-in user's list.
/// `DELETE /manga/{manga_id}/my_list_status` (requires a token)
///
/// MyAnimeList answers 404 when the manga is not on the list.
public struct DeleteMangaListItemRequest: MALRequest {
    public typealias Response = MALEmptyResponse

    public let mangaID: Int

    /// - Parameter mangaID: The MyAnimeList manga id.
    public init(mangaID: Int) {
        self.mangaID = mangaID
    }

    public var method: HTTPMethod { .delete }
    public var path: String { "/manga/\(mangaID)/my_list_status" }
}
