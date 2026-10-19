import XCTest
@testable import mal

internal final class ModelDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try MALTransport.decoder.decode(T.self, from: Data(json.utf8))
    }

    internal func testAnimeDetailsDecodesLiveShapes() throws {
        // Trimmed from GET /anime/52991 with every details field.
        let anime = try decode(Anime.self, """
        {
          "id": 52991, "title": "Sousou no Frieren",
          "main_picture": {"medium": "https://cdn/m.jpg", "large": "https://cdn/l.jpg"},
          "alternative_titles": {"synonyms": ["Frieren at the Funeral"], "en": "Frieren: Beyond Journey's End", "ja": "葬送のフリーレン"},
          "start_date": "2023-09-29", "end_date": "2024-03",
          "mean": 9.24, "rank": 1, "num_list_users": 1531972, "nsfw": "white",
          "genres": [{"id": 2, "name": "Adventure"}],
          "created_at": "2022-09-09T10:01:30+00:00",
          "media_type": "tv_special", "status": "finished_airing", "num_episodes": 28,
          "start_season": {"year": 2023, "season": "fall"},
          "broadcast": {"day_of_the_week": "friday", "start_time": "23:00"},
          "source": "manga", "average_episode_duration": 1470, "rating": "pg_13",
          "studios": [{"id": 11, "name": "Madhouse"}],
          "related_anime": [{"node": {"id": 56805, "title": "Yuusha"}, "relation_type": "other", "relation_type_formatted": "Other"}],
          "related_manga": [],
          "recommendations": [{"node": {"id": 37521, "title": "Vinland Saga"}, "num_recommendations": 30}],
          "statistics": {"status": {"watching": "242040", "completed": "1013599", "on_hold": "31630", "dropped": "25816", "plan_to_watch": "218887"}, "num_list_users": 1531972}
        }
        """)

        XCTAssertEqual(anime.alternativeTitles?.english, "Frieren: Beyond Journey's End")
        XCTAssertEqual(anime.alternativeTitles?.japanese, "葬送のフリーレン")
        XCTAssertEqual(anime.startDate, MALDate(year: 2023, month: 9, day: 29))
        XCTAssertEqual(anime.endDate, MALDate(year: 2024, month: 3))
        XCTAssertEqual(anime.mediaType, .tvSpecial)
        XCTAssertEqual(anime.startSeason, AnimeSeason(year: 2023, season: .fall))
        XCTAssertEqual(anime.broadcast?.dayOfTheWeek, "friday")
        XCTAssertEqual(anime.rating, .teens)
        XCTAssertEqual(anime.createdAt, Date(timeIntervalSince1970: 1_662_717_690))
        XCTAssertEqual(anime.relatedAnime?.first?.relationType, .other)
        XCTAssertEqual(anime.recommendations?.first?.node.title, "Vinland Saga")
        XCTAssertEqual(anime.recommendations?.first?.numRecommendations, 30)
        XCTAssertEqual(anime.statistics?.completed, 1_013_599)
        XCTAssertEqual(anime.statistics?.planToWatch, 218_887)
        XCTAssertEqual(anime.statistics?.numListUsers, 1_531_972)
        XCTAssertNil(anime.myListStatus)
    }

    internal func testUnknownEnumValuesArePreserved() throws {
        let anime = try decode(Anime.self, #"{"id": 1, "title": "X", "media_type": "web_series", "status": "on_break", "source": "podcast"}"#)

        XCTAssertEqual(anime.mediaType?.rawValue, "web_series")
        XCTAssertEqual(anime.status?.rawValue, "on_break")
        XCTAssertEqual(anime.source?.rawValue, "podcast")
    }

    internal func testMangaDecodesAuthorsSerializationAndUndocumentedValues() throws {
        let manga = try decode(Manga.self, """
        {
          "id": 2, "title": "Berserk", "media_type": "light_novel", "status": "on_hiatus", "num_volumes": 0, "num_chapters": 0,
          "authors": [{"node": {"id": 1868, "first_name": "Kentarou", "last_name": "Miura"}, "role": "Story & Art"}],
          "serialization": [{"node": {"id": 2, "name": "Young Animal"}}]
        }
        """)

        XCTAssertEqual(manga.mediaType, .lightNovel)
        XCTAssertEqual(manga.status, .onHiatus)
        XCTAssertEqual(manga.authors?.first?.node.lastName, "Miura")
        XCTAssertEqual(manga.authors?.first?.role, "Story & Art")
        XCTAssertEqual(manga.serialization?.first?.node.name, "Young Animal")
    }

    internal func testUserListPageDecodesEntriesAndNextOffset() throws {
        let page = try decode(MALPage<MangaListEntry>.self, """
        {
          "data": [{
            "node": {"id": 32, "title": "666 Satan", "num_chapters": 78},
            "list_status": {"status": "plan_to_read", "is_rereading": false, "num_volumes_read": 0, "num_chapters_read": 0, "score": 0,
                            "updated_at": "2007-08-23T04:28:01+00:00", "comments": "", "tags": ["shelf"], "priority": 0, "num_times_reread": 0, "reread_value": 0}
          }],
          "paging": {"next": "https://api.myanimelist.net/v2/users/Xinil/mangalist?offset=1&limit=1&fields=list_status%7Bcomments%7D"}
        }
        """)

        let entry = try XCTUnwrap(page.data.first)
        XCTAssertEqual(entry.node.numChapters, 78)
        XCTAssertEqual(entry.listStatus?.status, .planToRead)
        XCTAssertEqual(entry.listStatus?.isRereading, false)
        XCTAssertEqual(entry.listStatus?.tags, ["shelf"])
        XCTAssertEqual(page.paging.nextOffset, 1)
        XCTAssertNil(page.paging.previousOffset)
    }

    internal func testEmptyPageHasNoNextOffset() throws {
        let page = try decode(MALPage<MALRankedNode<Anime>>.self, #"{"data": [], "paging": {}}"#)

        XCTAssertTrue(page.data.isEmpty)
        XCTAssertNil(page.paging.nextOffset)
    }

    internal func testPreviousOffsetWithoutOffsetParameterIsZero() {
        let paging = Paging(previous: "https://api.myanimelist.net/v2/anime?q=frieren&limit=1", next: nil)

        XCTAssertEqual(paging.previousOffset, 0)
    }

    internal func testForumTopicAcceptsPollObjectOrArray() throws {
        let post = #"{"id": 15582, "number": 1, "created_at": "2007-02-11T00:47:26+00:00", "created_by": {"id": 1485, "name": "manish", "forum_avator": "https://cdn/a.gif"}, "body": "<b>hi</b>", "signature": ""}"#
        let poll = #"{"id": 32, "question": "Rate it", "closed": false, "options": [{"id": 143, "text": "5", "votes": 16}]}"#

        let object = try decode(ForumTopicPage.self, #"{"data": {"title": "Ep 2", "posts": [\#(post)], "poll": \#(poll)}, "paging": {}}"#)
        let array = try decode(ForumTopicPage.self, #"{"data": {"title": "Ep 2", "posts": [], "poll": [\#(poll)]}, "paging": {}}"#)

        XCTAssertEqual(object.data.posts.first?.createdBy?.forumAvatar, "https://cdn/a.gif")
        XCTAssertEqual(object.data.poll?.options.first?.votes, 16)
        XCTAssertEqual(array.data.poll?.id, 32)
    }

    internal func testMALDateParsesPartialDatesAndRejectsGarbage() {
        XCTAssertEqual(MALDate(string: "2017"), MALDate(year: 2017))
        XCTAssertEqual(MALDate(string: "2017-10"), MALDate(year: 2017, month: 10))
        XCTAssertEqual(MALDate(string: "2017-10-23"), MALDate(year: 2017, month: 10, day: 23))
        XCTAssertNil(MALDate(string: "2017-xx"))
        XCTAssertNil(MALDate(string: "2017-10-23-1"))
        XCTAssertNil(MALDate(string: ""))
        XCTAssertEqual(MALDate(year: 2024, month: 1, day: 5).description, "2024-01-05")
        XCTAssertEqual(MALDate(year: 2024, day: 5).description, "2024")
    }
}
