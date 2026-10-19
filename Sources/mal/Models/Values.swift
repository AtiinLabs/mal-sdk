import Foundation

/// A string value from a MyAnimeList enumeration.
///
/// MyAnimeList returns values its documentation does not list (for example the anime media
/// types `tv_special`, `pv` and `cm`, or the manga statuses `on_hiatus` and `discontinued`), and
/// adds new ones without notice. These types therefore keep any raw string instead of failing to
/// decode; the known values are static members.
public protocol MALValue: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral where RawValue == String {
    /// Creates a value from MyAnimeList's raw string.
    init(rawValue: String)
}

public extension MALValue {
    /// Creates a value from a string literal.
    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

/// An anime's media type.
public struct AnimeMediaType: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let unknown: Self = "unknown"
    public static let tvSeries: Self = "tv"
    public static let ova: Self = "ova"
    public static let movie: Self = "movie"
    public static let special: Self = "special"
    public static let ona: Self = "ona"
    public static let music: Self = "music"
    public static let tvSpecial: Self = "tv_special"
    public static let promotionalVideo: Self = "pv"
    public static let commercial: Self = "cm"
}

/// An anime's airing status.
public struct AnimeStatus: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let finishedAiring: Self = "finished_airing"
    public static let currentlyAiring: Self = "currently_airing"
    public static let notYetAired: Self = "not_yet_aired"
}

/// A manga's media type.
public struct MangaMediaType: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let unknown: Self = "unknown"
    public static let manga: Self = "manga"
    public static let novel: Self = "novel"
    public static let lightNovel: Self = "light_novel"
    public static let oneShot: Self = "one_shot"
    public static let doujinshi: Self = "doujinshi"
    public static let manhwa: Self = "manhwa"
    public static let manhua: Self = "manhua"
    public static let oel: Self = "oel"
}

/// A manga's publishing status.
public struct MangaStatus: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let finished: Self = "finished"
    public static let currentlyPublishing: Self = "currently_publishing"
    public static let notYetPublished: Self = "not_yet_published"
    public static let onHiatus: Self = "on_hiatus"
    public static let discontinued: Self = "discontinued"
}

/// The status of an anime on a user's list.
public struct AnimeWatchStatus: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let watching: Self = "watching"
    public static let completed: Self = "completed"
    public static let onHold: Self = "on_hold"
    public static let dropped: Self = "dropped"
    public static let planToWatch: Self = "plan_to_watch"
}

/// The status of a manga on a user's list.
public struct MangaReadStatus: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let reading: Self = "reading"
    public static let completed: Self = "completed"
    public static let onHold: Self = "on_hold"
    public static let dropped: Self = "dropped"
    public static let planToRead: Self = "plan_to_read"
}

/// A broadcast season.
public struct SeasonName: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// January to March.
    public static let winter: Self = "winter"
    /// April to June.
    public static let spring: Self = "spring"
    /// July to September.
    public static let summer: Self = "summer"
    /// October to December.
    public static let fall: Self = "fall"
}

/// How safe for work a title is.
public struct NSFWLevel: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Safe for work.
    public static let white: Self = "white"
    /// May be not safe for work.
    public static let gray: Self = "gray"
    /// Not safe for work.
    public static let black: Self = "black"
}

/// An anime's age rating.
public struct AnimeRating: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// G - All Ages.
    public static let allAges: Self = "g"
    /// PG - Children.
    public static let children: Self = "pg"
    /// PG-13 - Teens 13 and older.
    public static let teens: Self = "pg_13"
    /// R - 17+ (violence & profanity).
    public static let restricted: Self = "r"
    /// R+ - Mild nudity.
    public static let mildNudity: Self = "r+"
    /// Rx - Hentai.
    public static let hentai: Self = "rx"
}

/// The original work an anime adapts.
public struct AnimeSource: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let other: Self = "other"
    public static let original: Self = "original"
    public static let manga: Self = "manga"
    public static let fourKomaManga: Self = "4_koma_manga"
    public static let webManga: Self = "web_manga"
    public static let digitalManga: Self = "digital_manga"
    public static let novel: Self = "novel"
    public static let lightNovel: Self = "light_novel"
    public static let visualNovel: Self = "visual_novel"
    public static let game: Self = "game"
    public static let cardGame: Self = "card_game"
    public static let book: Self = "book"
    public static let pictureBook: Self = "picture_book"
    public static let radio: Self = "radio"
    public static let music: Self = "music"
}

/// How a related work relates to the current one, for example `sequel` or `adaptation`.
public struct RelationType: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let sequel: Self = "sequel"
    public static let prequel: Self = "prequel"
    public static let alternativeSetting: Self = "alternative_setting"
    public static let alternativeVersion: Self = "alternative_version"
    public static let sideStory: Self = "side_story"
    public static let parentStory: Self = "parent_story"
    public static let summary: Self = "summary"
    public static let fullStory: Self = "full_story"
    public static let adaptation: Self = "adaptation"
    public static let spinOff: Self = "spin_off"
    public static let character: Self = "character"
    public static let other: Self = "other"
}

/// An anime ranking.
public struct AnimeRankingType: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Top anime series.
    public static let all: Self = "all"
    /// Top airing anime.
    public static let airing: Self = "airing"
    /// Top upcoming anime.
    public static let upcoming: Self = "upcoming"
    /// Top anime TV series.
    public static let tvSeries: Self = "tv"
    /// Top OVA series.
    public static let ova: Self = "ova"
    /// Top anime movies.
    public static let movie: Self = "movie"
    /// Top anime specials.
    public static let special: Self = "special"
    /// Most popular anime.
    public static let byPopularity: Self = "bypopularity"
    /// Most favorited anime.
    public static let favorite: Self = "favorite"
}

/// A manga ranking.
public struct MangaRankingType: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let all: Self = "all"
    public static let manga: Self = "manga"
    public static let novels: Self = "novels"
    public static let oneShots: Self = "oneshots"
    public static let doujin: Self = "doujin"
    public static let manhwa: Self = "manhwa"
    public static let manhua: Self = "manhua"
    /// Most popular manga.
    public static let byPopularity: Self = "bypopularity"
    /// Most favorited manga.
    public static let favorite: Self = "favorite"
}

/// Sort order for seasonal anime. Both sort descending.
public struct SeasonalAnimeSort: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let score: Self = "anime_score"
    public static let numListUsers: Self = "anime_num_list_users"
}

/// Sort order for a user's anime list.
public struct UserAnimeListSort: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// List score, descending.
    public static let listScore: Self = "list_score"
    /// Last update, descending.
    public static let listUpdatedAt: Self = "list_updated_at"
    /// Title, ascending.
    public static let animeTitle: Self = "anime_title"
    /// Start date, descending.
    public static let animeStartDate: Self = "anime_start_date"
}

/// Sort order for a user's manga list.
public struct UserMangaListSort: MALValue {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// List score, descending.
    public static let listScore: Self = "list_score"
    /// Last update, descending.
    public static let listUpdatedAt: Self = "list_updated_at"
    /// Title, ascending.
    public static let mangaTitle: Self = "manga_title"
    /// Start date, descending.
    public static let mangaStartDate: Self = "manga_start_date"
}
