import Foundation

/// An image in two sizes.
public struct Picture: Codable, Hashable, Sendable {
    public let medium: String?
    public let large: String?
}

/// Alternative titles of a work.
public struct AlternativeTitles: Codable, Hashable, Sendable {
    public let synonyms: [String]?
    /// English title (`en`).
    public let english: String?
    /// Japanese title (`ja`).
    public let japanese: String?

    public enum CodingKeys: String, CodingKey {
        case synonyms
        case english = "en"
        case japanese = "ja"
    }
}

/// A genre.
public struct Genre: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
}

/// A date that may lack a month or day, as MyAnimeList stores them: `2017-10-23`, `2017-10` or `2017`.
public struct MALDate: Codable, Hashable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int?
    public let day: Int?

    /// Creates a date. A `day` without a `month` is ignored.
    public init(year: Int, month: Int? = nil, day: Int? = nil) {
        self.year = year
        self.month = month
        self.day = month == nil ? nil : day
    }

    /// Parses `YYYY`, `YYYY-MM` or `YYYY-MM-DD`.
    public init?(string: String) {
        let parts = string.split(separator: "-").map { Int($0) }
        guard (1...3).contains(parts.count), let year = parts[0] else {
            return nil
        }
        let month = parts.count > 1 ? parts[1] : nil
        let day = parts.count > 2 ? parts[2] : nil
        if parts.count > 1 && month == nil || parts.count > 2 && day == nil {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    /// The MyAnimeList string form, e.g. `2017-10-23`.
    public var description: String {
        var string = String(format: "%04d", year)
        if let month {
            string += String(format: "-%02d", month)
            if let day {
                string += String(format: "-%02d", day)
            }
        }
        return string
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = MALDate(string: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid MyAnimeList date: \(string)")
        }
        self = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// Links to the previous and next pages.
public struct Paging: Codable, Hashable, Sendable {
    public let previous: String?
    public let next: String?

    /// The `offset` of the next page, or `nil` on the last page.
    public var nextOffset: Int? {
        Self.offset(in: next)
    }

    /// The `offset` of the previous page, or `nil` on the first page.
    public var previousOffset: Int? {
        Self.offset(in: previous)
    }

    private static func offset(in link: String?) -> Int? {
        guard let link, let components = URLComponents(string: link) else {
            return nil
        }
        return components.queryItems?.first { $0.name == "offset" }?.value.flatMap { Int($0) } ?? 0
    }
}

/// One page of a list endpoint. Request the next page with `paging.nextOffset`.
public struct MALPage<Item: Decodable & Sendable>: Decodable, Sendable {
    public let data: [Item]
    public let paging: Paging

    public enum CodingKeys: String, CodingKey {
        case data, paging
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decodeIfPresent([Item].self, forKey: .data) ?? []
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging) ?? Paging(previous: nil, next: nil)
    }
}

/// A work wrapped in MyAnimeList's `{"node": …}` envelope.
public struct MALNode<Item: Decodable & Sendable>: Decodable, Sendable {
    public let node: Item
}

/// A work in a ranking.
public struct MALRankedNode<Item: Decodable & Sendable>: Decodable, Sendable {
    public let node: Item
    public let ranking: Ranking?
}

/// A position in a ranking.
public struct Ranking: Codable, Hashable, Sendable {
    public let rank: Int
    public let previousRank: Int?
}

/// A related work and how it relates to the current one.
public struct RelatedWork<Item: Decodable & Sendable>: Decodable, Sendable {
    public let node: Item
    public let relationType: RelationType?
    /// The relation for display, e.g. "Alternative version".
    public let relationTypeFormatted: String?
}

/// A recommended work and how many users recommended it.
public struct Recommendation<Item: Decodable & Sendable>: Decodable, Sendable {
    public let node: Item
    public let numRecommendations: Int?
}

/// An integer MyAnimeList sometimes sends as a string (for example anime statistics counts).
internal struct LenientInt: Decodable {
    internal let value: Int

    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let int = Int(try container.decode(String.self)) {
            value = int
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an integer")
        }
    }
}
