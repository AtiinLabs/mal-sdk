import Foundation

/// The forum's boards, grouped by category.
public struct ForumBoards: Decodable, Sendable {
    public let categories: [ForumCategory]
}

/// A forum category.
public struct ForumCategory: Decodable, Sendable {
    public let title: String
    public let boards: [ForumBoard]
}

/// A forum board.
public struct ForumBoard: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let description: String?
    public let subboards: [ForumSubboard]?
}

/// A forum subboard.
public struct ForumSubboard: Decodable, Sendable {
    public let id: Int
    public let title: String
}

/// A forum member as shown on topics.
public struct ForumUser: Decodable, Sendable {
    public let id: Int
    public let name: String
}

/// A topic in a topic list.
public struct ForumTopicSummary: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let createdAt: Date?
    public let createdBy: ForumUser?
    public let numberOfPosts: Int?
    public let lastPostCreatedAt: Date?
    public let lastPostCreatedBy: ForumUser?
    // swiftlint:disable:next discouraged_optional_boolean
    public let isLocked: Bool?
}

/// One page of a topic's posts.
public struct ForumTopicPage: Decodable, Sendable {
    public let data: ForumTopic
    public let paging: Paging

    public enum CodingKeys: String, CodingKey {
        case data, paging
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(ForumTopic.self, forKey: .data)
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging) ?? Paging(previous: nil, next: nil)
    }
}

/// A topic with a page of its posts.
public struct ForumTopic: Decodable, Sendable {
    public let title: String
    public let posts: [ForumPost]
    public let poll: ForumPoll?

    public enum CodingKeys: String, CodingKey {
        case title, posts, poll
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.posts = try container.decodeIfPresent([ForumPost].self, forKey: .posts) ?? []
        // The API sends one poll object; its specification documents an array.
        if let poll = try? container.decodeIfPresent(ForumPoll.self, forKey: .poll) {
            self.poll = poll
        } else {
            self.poll = try? container.decodeIfPresent([ForumPoll].self, forKey: .poll)?.first
        }
    }
}

/// A forum post. `body` and `signature` are HTML.
public struct ForumPost: Decodable, Sendable {
    public let id: Int
    public let number: Int?
    public let createdAt: Date?
    public let createdBy: ForumPostAuthor?
    public let body: String?
    public let signature: String?
}

/// A post's author.
public struct ForumPostAuthor: Decodable, Sendable {
    public let id: Int
    public let name: String
    /// Avatar URL. MyAnimeList spells the key `forum_avator`.
    public let forumAvatar: String?

    public enum CodingKeys: String, CodingKey {
        case id, name
        case forumAvatar = "forumAvator"
    }
}

/// A topic's poll.
public struct ForumPoll: Decodable, Sendable {
    public let id: Int
    public let question: String
    // swiftlint:disable:next discouraged_optional_boolean
    public let closed: Bool?
    public let options: [ForumPollOption]
}

/// A poll option.
public struct ForumPollOption: Decodable, Sendable {
    public let id: Int
    public let text: String
    public let votes: Int
}
