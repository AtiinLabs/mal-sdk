import Foundation

/// An anime. Every field except `id` and `title` is present only when requested with `AnimeField`.
public struct Anime: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let mainPicture: Picture?
    public let alternativeTitles: AlternativeTitles?
    public let startDate: MALDate?
    public let endDate: MALDate?
    /// Synopsis with BBCode stripped.
    public let synopsis: String?
    /// Mean score; absent when too few users scored it.
    public let mean: Double?
    /// Rank by score; absent when too few users scored it.
    public let rank: Int?
    public let popularity: Int?
    public let numListUsers: Int?
    public let numScoringUsers: Int?
    public let nsfw: NSFWLevel?
    public let genres: [Genre]?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let mediaType: AnimeMediaType?
    public let status: AnimeStatus?
    /// The signed-in user's entry, when requested with a token and the anime is on their list.
    public let myListStatus: AnimeListStatus?
    /// Total episodes; 0 when unknown.
    public let numEpisodes: Int?
    public let startSeason: AnimeSeason?
    public let broadcast: Broadcast?
    public let source: AnimeSource?
    /// Average episode length in seconds.
    public let averageEpisodeDuration: Int?
    public let rating: AnimeRating?
    public let studios: [Studio]?
    public let pictures: [Picture]?
    /// Background information with BBCode stripped.
    public let background: String?
    public let relatedAnime: [RelatedWork<Anime>]?
    public let relatedManga: [RelatedWork<Manga>]?
    public let recommendations: [Recommendation<Anime>]?
    public let statistics: AnimeStatistics?
}

/// The season an anime started airing.
public struct AnimeSeason: Codable, Hashable, Sendable {
    public let year: Int
    public let season: SeasonName

    public init(year: Int, season: SeasonName) {
        self.year = year
        self.season = season
    }
}

/// When an anime airs in Japan.
public struct Broadcast: Codable, Hashable, Sendable {
    /// Lowercase English weekday, e.g. `friday`, or `other`.
    public let dayOfTheWeek: String?
    /// Japan Standard Time, `HH:mm`.
    public let startTime: String?
}

/// An animation studio.
public struct Studio: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
}

/// How many users have an anime on their list, by status.
public struct AnimeStatistics: Decodable, Hashable, Sendable {
    public let numListUsers: Int?
    public let watching: Int?
    public let completed: Int?
    public let onHold: Int?
    public let dropped: Int?
    public let planToWatch: Int?

    public enum CodingKeys: String, CodingKey {
        case numListUsers, status
    }

    private enum StatusKeys: String, CodingKey {
        case watching, completed, onHold, dropped, planToWatch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.numListUsers = try container.decodeIfPresent(LenientInt.self, forKey: .numListUsers)?.value
        // MyAnimeList sends these counts as strings.
        let status = try? container.nestedContainer(keyedBy: StatusKeys.self, forKey: .status)
        self.watching = try status?.decodeIfPresent(LenientInt.self, forKey: .watching)?.value
        self.completed = try status?.decodeIfPresent(LenientInt.self, forKey: .completed)?.value
        self.onHold = try status?.decodeIfPresent(LenientInt.self, forKey: .onHold)?.value
        self.dropped = try status?.decodeIfPresent(LenientInt.self, forKey: .dropped)?.value
        self.planToWatch = try status?.decodeIfPresent(LenientInt.self, forKey: .planToWatch)?.value
    }
}

/// A user's list entry for an anime.
public struct AnimeListStatus: Decodable, Sendable {
    public let status: AnimeWatchStatus?
    /// 0 (unscored) to 10.
    public let score: Int?
    public let numEpisodesWatched: Int?
    /// Rewatching after completion; MyAnimeList then treats the anime as watching.
    public let isRewatching: Bool? // swiftlint:disable:this discouraged_optional_boolean
    public let startDate: MALDate?
    public let finishDate: MALDate?
    /// 0 (low) to 2 (high).
    public let priority: Int?
    public let numTimesRewatched: Int?
    /// 0 to 5.
    public let rewatchValue: Int?
    public let tags: [String]?
    public let comments: String?
    public let updatedAt: Date?
}

/// An anime on a user's list.
public struct AnimeListEntry: Decodable, Sendable {
    public let node: Anime
    public let listStatus: AnimeListStatus?
}

/// One page of seasonal anime.
public struct SeasonalAnimePage: Decodable, Sendable {
    public let data: [MALNode<Anime>]
    public let paging: Paging
    /// The requested season.
    public let season: AnimeSeason?

    public enum CodingKeys: String, CodingKey {
        case data, paging, season
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decodeIfPresent([MALNode<Anime>].self, forKey: .data) ?? []
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging) ?? Paging(previous: nil, next: nil)
        self.season = try container.decodeIfPresent(AnimeSeason.self, forKey: .season)
    }
}
