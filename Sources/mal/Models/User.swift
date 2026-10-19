import Foundation

/// A MyAnimeList user.
public struct User: Decodable, Sendable {
    public let id: Int
    public let name: String
    /// Avatar URL.
    public let picture: String?
    public let gender: String?
    public let birthday: MALDate?
    public let location: String?
    public let joinedAt: Date?
    public let animeStatistics: UserAnimeStatistics?
    /// For example `America/Los_Angeles`.
    public let timeZone: String?
    // swiftlint:disable:next discouraged_optional_boolean
    public let isSupporter: Bool?
}

/// A user's anime list totals.
public struct UserAnimeStatistics: Decodable, Hashable, Sendable {
    public let numItemsWatching: Int?
    public let numItemsCompleted: Int?
    public let numItemsOnHold: Int?
    public let numItemsDropped: Int?
    public let numItemsPlanToWatch: Int?
    public let numItems: Int?
    public let numDaysWatched: Double?
    public let numDaysWatching: Double?
    public let numDaysCompleted: Double?
    public let numDaysOnHold: Double?
    public let numDaysDropped: Double?
    public let numDays: Double?
    public let numEpisodes: Int?
    public let numTimesRewatched: Int?
    public let meanScore: Double?
}
