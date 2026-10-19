import Foundation

/// Searches anime by title. `GET /anime`
///
/// MyAnimeList rejects queries shorter than 3 characters with HTTP 400 (`invalid q`).
public struct AnimeSearchRequest: MALRequest {
    public typealias Response = MALPage<MALNode<Anime>>

    public let query: String
    public let limit: Int
    public let offset: Int
    public let fields: [AnimeField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - query: Search text, 3 or more characters.
    ///   - limit: Results per page, 1 to 100.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(query: String, limit: Int = 100, offset: Int = 0, fields: [AnimeField] = AnimeField.list, includeNSFW: Bool = false) {
        self.query = query
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/anime" }

    public var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "q", value: query)]
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Fetches one anime. `GET /anime/{anime_id}`
public struct AnimeDetailsRequest: MALRequest {
    public typealias Response = Anime

    public let id: Int
    public let fields: [AnimeField]

    /// - Parameters:
    ///   - id: The MyAnimeList anime id.
    ///   - fields: Fields to return. Defaults to every field.
    public init(id: Int, fields: [AnimeField] = AnimeField.details) {
        self.id = id
        self.fields = fields
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/anime/\(id)" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendFields(fields)
        return items
    }
}

/// Fetches an anime ranking. `GET /anime/ranking`
public struct AnimeRankingRequest: MALRequest {
    public typealias Response = MALPage<MALRankedNode<Anime>>

    public let type: AnimeRankingType
    public let limit: Int
    public let offset: Int
    public let fields: [AnimeField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - type: The ranking.
    ///   - limit: Results per page, 1 to 500.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(type: AnimeRankingType = .all, limit: Int = 100, offset: Int = 0, fields: [AnimeField] = AnimeField.list, includeNSFW: Bool = false) {
        self.type = type
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/anime/ranking" }

    public var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "ranking_type", value: type.rawValue)]
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Fetches the anime of a broadcast season. `GET /anime/season/{year}/{season}`
///
/// MyAnimeList answers 404 for seasons it has no anime for.
public struct SeasonalAnimeRequest: MALRequest {
    public typealias Response = SeasonalAnimePage

    public let year: Int
    public let season: SeasonName
    public let sort: SeasonalAnimeSort?
    public let limit: Int
    public let offset: Int
    public let fields: [AnimeField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - year: The year.
    ///   - season: The season.
    ///   - sort: Sort order; MyAnimeList's default when `nil`.
    ///   - limit: Results per page, 1 to 500.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(year: Int, season: SeasonName, sort: SeasonalAnimeSort? = nil, limit: Int = 100, offset: Int = 0, fields: [AnimeField] = AnimeField.list, includeNSFW: Bool = false) {
        self.year = year
        self.season = season
        self.sort = sort
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/anime/season/\(year)/\(season.rawValue)" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append("sort", sort?.rawValue)
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Fetches anime MyAnimeList suggests for the signed-in user; empty for new users.
/// `GET /anime/suggestions` (requires a token)
public struct AnimeSuggestionsRequest: MALRequest {
    public typealias Response = MALPage<MALNode<Anime>>

    public let limit: Int
    public let offset: Int
    public let fields: [AnimeField]
    public let includeNSFW: Bool

    /// - Parameters:
    ///   - limit: Results per page, 1 to 100.
    ///   - offset: Results to skip.
    ///   - fields: Fields to return. Defaults to every list field.
    ///   - includeNSFW: Also return works MyAnimeList marks not safe for work.
    public init(limit: Int = 100, offset: Int = 0, fields: [AnimeField] = AnimeField.list, includeNSFW: Bool = false) {
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.includeNSFW = includeNSFW
    }

    public var method: HTTPMethod { .get }
    public var path: String { "/anime/suggestions" }

    public var queryItems: [URLQueryItem] {
        listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW)
    }
}

/// Fetches a user's anime list. `GET /users/{user_name}/animelist`
///
/// MyAnimeList answers 404 for unknown users.
public struct UserAnimeListRequest: MALRequest {
    public typealias Response = MALPage<AnimeListEntry>

    public let userName: String
    public let status: AnimeWatchStatus?
    public let sort: UserAnimeListSort?
    public let limit: Int
    public let offset: Int
    public let fields: [AnimeField]
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
        status: AnimeWatchStatus? = nil,
        sort: UserAnimeListSort? = nil,
        limit: Int = 1000,
        offset: Int = 0,
        fields: [AnimeField] = [.listStatusAll] + AnimeField.list.filter { $0 != .myListStatus },
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
    public var path: String { "/users/\(userName)/animelist" }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append("status", status?.rawValue)
        items.append("sort", sort?.rawValue)
        items.append(contentsOf: listQueryItems(limit: limit, offset: offset, fields: fields, includeNSFW: includeNSFW))
        return items
    }
}

/// Adds an anime to the signed-in user's list or updates its entry.
/// `PATCH /anime/{anime_id}/my_list_status` (requires a token)
///
/// Only non-`nil` fields are sent; other fields keep their values.
public struct UpdateAnimeListStatusRequest: MALRequest {
    public typealias Response = AnimeListStatus

    public let animeID: Int
    public let status: AnimeWatchStatus?
    // swiftlint:disable:next discouraged_optional_boolean
    public let isRewatching: Bool?
    public let score: Int?
    public let numWatchedEpisodes: Int?
    public let priority: Int?
    public let numTimesRewatched: Int?
    public let rewatchValue: Int?
    public let tags: [String]?
    public let comments: String?
    public let startDate: MALDate?
    public let finishDate: MALDate?

    /// - Parameters:
    ///   - animeID: The MyAnimeList anime id.
    ///   - status: The list status.
    ///   - isRewatching: Rewatching after completion.
    ///   - score: 0 (unscored) to 10.
    ///   - numWatchedEpisodes: Episodes watched.
    ///   - priority: 0 (low) to 2 (high).
    ///   - numTimesRewatched: Completed rewatches.
    ///   - rewatchValue: 0 to 5.
    ///   - tags: Tags; replaces existing tags.
    ///   - comments: Notes.
    ///   - startDate: When the user started.
    ///   - finishDate: When the user finished.
    public init(
        animeID: Int,
        status: AnimeWatchStatus? = nil,
        // swiftlint:disable:next discouraged_optional_boolean
        isRewatching: Bool? = nil,
        score: Int? = nil,
        numWatchedEpisodes: Int? = nil,
        priority: Int? = nil,
        numTimesRewatched: Int? = nil,
        rewatchValue: Int? = nil,
        tags: [String]? = nil,
        comments: String? = nil,
        startDate: MALDate? = nil,
        finishDate: MALDate? = nil
    ) {
        self.animeID = animeID
        self.status = status
        self.isRewatching = isRewatching
        self.score = score
        self.numWatchedEpisodes = numWatchedEpisodes
        self.priority = priority
        self.numTimesRewatched = numTimesRewatched
        self.rewatchValue = rewatchValue
        self.tags = tags
        self.comments = comments
        self.startDate = startDate
        self.finishDate = finishDate
    }

    public var method: HTTPMethod { .patch }
    public var path: String { "/anime/\(animeID)/my_list_status" }

    public var formFields: [URLQueryItem]? {
        var items: [URLQueryItem] = []
        items.append("status", status?.rawValue)
        items.append("is_rewatching", isRewatching)
        items.append("score", score)
        items.append("num_watched_episodes", numWatchedEpisodes)
        items.append("priority", priority)
        items.append("num_times_rewatched", numTimesRewatched)
        items.append("rewatch_value", rewatchValue)
        items.append("tags", tags?.joined(separator: ","))
        items.append("comments", comments)
        items.append("start_date", startDate?.description)
        items.append("finish_date", finishDate?.description)
        return items
    }
}

/// Removes an anime from the signed-in user's list.
/// `DELETE /anime/{anime_id}/my_list_status` (requires a token)
///
/// MyAnimeList answers 404 when the anime is not on the list.
public struct DeleteAnimeListItemRequest: MALRequest {
    public typealias Response = MALEmptyResponse

    public let animeID: Int

    /// - Parameter animeID: The MyAnimeList anime id.
    public init(animeID: Int) {
        self.animeID = animeID
    }

    public var method: HTTPMethod { .delete }
    public var path: String { "/anime/\(animeID)/my_list_status" }
}

/// `limit`, `offset`, `fields` and `nsfw` for list endpoints.
internal func listQueryItems<F: MALField>(limit: Int, offset: Int, fields: [F], includeNSFW: Bool) -> [URLQueryItem] {
    var items = [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
    ]
    items.appendFields(fields)
    if includeNSFW {
        items.append(URLQueryItem(name: "nsfw", value: "true"))
    }
    return items
}
