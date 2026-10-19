import Foundation

/// A manga, light novel or other print work. Every field except `id` and `title` is present only
/// when requested with `MangaField`.
public struct Manga: Decodable, Sendable {
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
    public let mediaType: MangaMediaType?
    public let status: MangaStatus?
    /// The signed-in user's entry, when requested with a token and the manga is on their list.
    public let myListStatus: MangaListStatus?
    /// Total volumes; 0 when unknown or still publishing.
    public let numVolumes: Int?
    /// Total chapters; 0 when unknown or still publishing.
    public let numChapters: Int?
    public let authors: [MangaAuthor]?
    public let pictures: [Picture]?
    /// Background information with BBCode stripped.
    public let background: String?
    public let relatedAnime: [RelatedWork<Anime>]?
    public let relatedManga: [RelatedWork<Manga>]?
    public let recommendations: [Recommendation<Manga>]?
    public let serialization: [MangaSerialization]?
}

/// A person credited on a manga.
public struct MangaAuthor: Decodable, Hashable, Sendable {
    public let node: Person
    /// The credit, e.g. `Story & Art`.
    public let role: String?
}

/// A person.
public struct Person: Decodable, Hashable, Sendable {
    public let id: Int
    public let firstName: String?
    public let lastName: String?
}

/// A magazine that serialized a manga.
public struct MangaSerialization: Decodable, Hashable, Sendable {
    public let node: Magazine
    public let role: String?
}

/// A magazine.
public struct Magazine: Decodable, Hashable, Sendable {
    public let id: Int
    public let name: String
}

/// A user's list entry for a manga.
public struct MangaListStatus: Decodable, Sendable {
    public let status: MangaReadStatus?
    /// 0 (unscored) to 10.
    public let score: Int?
    public let numVolumesRead: Int?
    public let numChaptersRead: Int?
    /// Rereading after completion; MyAnimeList then treats the manga as reading.
    public let isRereading: Bool? // swiftlint:disable:this discouraged_optional_boolean
    public let startDate: MALDate?
    public let finishDate: MALDate?
    /// 0 (low) to 2 (high).
    public let priority: Int?
    public let numTimesReread: Int?
    /// 0 to 5.
    public let rereadValue: Int?
    public let tags: [String]?
    public let comments: String?
    public let updatedAt: Date?
}

/// A manga on a user's list.
public struct MangaListEntry: Decodable, Sendable {
    public let node: Manga
    public let listStatus: MangaListStatus?
}
