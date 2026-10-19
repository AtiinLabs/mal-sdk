import Foundation

/// A field MyAnimeList returns only when the request names it in `fields`.
public protocol MALField: RawRepresentable, Hashable, Sendable where RawValue == String {}

/// An anime field for the `fields` parameter.
///
/// MyAnimeList returns only `id`, `title` and `main_picture` unless more fields are requested.
/// `pictures`, `background`, `related_anime`, `related_manga`, `recommendations` and
/// `statistics` are only allowed on the details endpoint.
public struct AnimeField: MALField, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let id: Self = "id"
    public static let title: Self = "title"
    public static let mainPicture: Self = "main_picture"
    public static let alternativeTitles: Self = "alternative_titles"
    public static let startDate: Self = "start_date"
    public static let endDate: Self = "end_date"
    public static let synopsis: Self = "synopsis"
    public static let mean: Self = "mean"
    public static let rank: Self = "rank"
    public static let popularity: Self = "popularity"
    public static let numListUsers: Self = "num_list_users"
    public static let numScoringUsers: Self = "num_scoring_users"
    public static let nsfw: Self = "nsfw"
    public static let genres: Self = "genres"
    public static let createdAt: Self = "created_at"
    public static let updatedAt: Self = "updated_at"
    public static let mediaType: Self = "media_type"
    public static let status: Self = "status"
    /// The signed-in user's list entry (requires a token).
    public static let myListStatus: Self = "my_list_status"
    /// The signed-in user's list entry including `tags` and `comments` (requires a token).
    public static let myListStatusAll: Self = "my_list_status{status,score,num_episodes_watched,is_rewatching,start_date,finish_date,priority,num_times_rewatched,rewatch_value,tags,comments,updated_at}"
    /// The list entry on user list endpoints.
    public static let listStatus: Self = "list_status"
    /// The list entry on user list endpoints, including `tags` and `comments`.
    public static let listStatusAll: Self = "list_status{status,score,num_episodes_watched,is_rewatching,start_date,finish_date,priority,num_times_rewatched,rewatch_value,tags,comments,updated_at}"
    public static let numEpisodes: Self = "num_episodes"
    public static let startSeason: Self = "start_season"
    public static let broadcast: Self = "broadcast"
    public static let source: Self = "source"
    public static let averageEpisodeDuration: Self = "average_episode_duration"
    public static let rating: Self = "rating"
    public static let studios: Self = "studios"
    /// Details only.
    public static let pictures: Self = "pictures"
    /// Details only.
    public static let background: Self = "background"
    /// Details only.
    public static let relatedAnime: Self = "related_anime"
    /// Details only.
    public static let relatedManga: Self = "related_manga"
    /// Details only.
    public static let recommendations: Self = "recommendations"
    /// Details only.
    public static let statistics: Self = "statistics"

    /// Every field allowed on list endpoints (search, ranking, seasonal, suggestions).
    public static let list: [Self] = [
        .id, .title, .mainPicture, .alternativeTitles, .startDate, .endDate, .synopsis, .mean, .rank,
        .popularity, .numListUsers, .numScoringUsers, .nsfw, .genres, .createdAt, .updatedAt, .mediaType,
        .status, .myListStatus, .numEpisodes, .startSeason, .broadcast, .source, .averageEpisodeDuration,
        .rating, .studios
    ]

    /// Every field allowed on the details endpoint.
    public static let details: [Self] = list.filter { $0 != .myListStatus } + [
        .myListStatusAll, .pictures, .background, .relatedAnime, .relatedManga, .recommendations, .statistics
    ]
}

/// A manga field for the `fields` parameter.
///
/// `pictures`, `background`, `related_anime`, `related_manga`, `recommendations` and
/// `serialization` are only allowed on the details endpoint.
public struct MangaField: MALField, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let id: Self = "id"
    public static let title: Self = "title"
    public static let mainPicture: Self = "main_picture"
    public static let alternativeTitles: Self = "alternative_titles"
    public static let startDate: Self = "start_date"
    public static let endDate: Self = "end_date"
    public static let synopsis: Self = "synopsis"
    public static let mean: Self = "mean"
    public static let rank: Self = "rank"
    public static let popularity: Self = "popularity"
    public static let numListUsers: Self = "num_list_users"
    public static let numScoringUsers: Self = "num_scoring_users"
    public static let nsfw: Self = "nsfw"
    public static let genres: Self = "genres"
    public static let createdAt: Self = "created_at"
    public static let updatedAt: Self = "updated_at"
    public static let mediaType: Self = "media_type"
    public static let status: Self = "status"
    /// The signed-in user's list entry (requires a token).
    public static let myListStatus: Self = "my_list_status"
    /// The signed-in user's list entry including `tags` and `comments` (requires a token).
    public static let myListStatusAll: Self = "my_list_status{status,score,num_volumes_read,num_chapters_read,is_rereading,start_date,finish_date,priority,num_times_reread,reread_value,tags,comments,updated_at}"
    /// The list entry on user list endpoints.
    public static let listStatus: Self = "list_status"
    /// The list entry on user list endpoints, including `tags` and `comments`.
    public static let listStatusAll: Self = "list_status{status,score,num_volumes_read,num_chapters_read,is_rereading,start_date,finish_date,priority,num_times_reread,reread_value,tags,comments,updated_at}"
    public static let numVolumes: Self = "num_volumes"
    public static let numChapters: Self = "num_chapters"
    public static let authors: Self = "authors{first_name,last_name}"
    /// Details only.
    public static let pictures: Self = "pictures"
    /// Details only.
    public static let background: Self = "background"
    /// Details only.
    public static let relatedAnime: Self = "related_anime"
    /// Details only.
    public static let relatedManga: Self = "related_manga"
    /// Details only.
    public static let recommendations: Self = "recommendations"
    /// Details only.
    public static let serialization: Self = "serialization{name}"

    /// Every field allowed on list endpoints (search, ranking).
    public static let list: [Self] = [
        .id, .title, .mainPicture, .alternativeTitles, .startDate, .endDate, .synopsis, .mean, .rank,
        .popularity, .numListUsers, .numScoringUsers, .nsfw, .genres, .createdAt, .updatedAt, .mediaType,
        .status, .myListStatus, .numVolumes, .numChapters, .authors
    ]

    /// Every field allowed on the details endpoint.
    public static let details: [Self] = list.filter { $0 != .myListStatus } + [
        .myListStatusAll, .pictures, .background, .relatedAnime, .relatedManga, .recommendations, .serialization
    ]
}

/// A user field for the `fields` parameter.
public struct UserField: MALField, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let animeStatistics: Self = "anime_statistics"
    public static let timeZone: Self = "time_zone"
    public static let isSupporter: Self = "is_supporter"

    /// Every optional user field.
    public static let all: [Self] = [.animeStatistics, .timeZone, .isSupporter]
}
