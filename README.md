# mal-sdk

Swift client for the [MyAnimeList API v2](https://myanimelist.net/apiconfig/references/api/v2), used by [Ito](https://github.com/AtiinLabs/Ito) alongside [anilist-sdk](https://github.com/AtiinLabs/anilist-sdk).

- Anime and manga search, details, rankings and seasonal anime
- User anime and manga lists, with list entry updates and deletion
- The signed-in user and their anime suggestions
- Forum boards, topics and posts
- OAuth 2.0 sign-in with PKCE, token exchange and refresh
- `Sendable` throughout, async/await, iOS 15 and macOS 12

## Installation

The package has no tagged releases yet, so pin a commit:

```swift
.package(url: "https://github.com/AtiinLabs/mal-sdk.git", revision: "<commit>")
```

Every request needs a client ID. Register an app at [myanimelist.net/apiconfig](https://myanimelist.net/apiconfig); pick "iOS", "Android" or "Other" for apps that run on the user's device, which get no client secret.

## Usage

```swift
import mal

let client = MALClient(clientID: "<client id>")

let page = try await client.execute(AnimeSearchRequest(query: "frieren", limit: 10))
for item in page.data {
    print(item.node.title, item.node.mediaType?.rawValue ?? "")
}
if let next = page.paging.nextOffset {
    let more = try await client.execute(AnimeSearchRequest(query: "frieren", limit: 10, offset: next))
}

let anime = try await client.execute(AnimeDetailsRequest(id: 52991))
let fall = try await client.execute(SeasonalAnimeRequest(year: 2024, season: .fall, sort: .numListUsers))
```

MyAnimeList returns only `id`, `title` and `main_picture` unless fields are requested. Requests default to every field the endpoint allows (`AnimeField.list` / `.details`, `MangaField.list` / `.details`); pass a shorter list to fetch less.

### Signing in

```swift
let oauth = MALOAuth(clientID: "<client id>")
let request = oauth.authorizationRequest()
// Open request.url (e.g. with ASWebAuthenticationSession) and wait for the redirect.
let code = try oauth.authorizationCode(from: callbackURL, matching: request)
var token = try await oauth.exchangeCode(code, for: request)
// Store token (it is Codable). Before token.expiresAt, or after a 401:
token = try await oauth.refresh(token)

let accessToken = token.accessToken
let userClient = MALClient(clientID: "<client id>") { accessToken }
let me = try await userClient.execute(CurrentUserRequest())
_ = try await userClient.execute(UpdateAnimeListStatusRequest(animeID: 52991, status: .watching, numWatchedEpisodes: 3))
```

MyAnimeList redirects to the URL registered for the app. Pass `redirectURI` only if the app registers several; it must match a registered URL exactly or the sign-in page answers `invalid_client`.

### Errors

Requests throw `MALError`. `isNotFound` (404: unknown id, user or season), `isUnauthorized` (401: missing, invalid or expired token) and `isForbidden` (403: no client ID, or too many requests) classify the common cases; `localizedDescription` includes MyAnimeList's error code and message. MyAnimeList publishes no rate limit and blocks clients that send too many requests, so space requests out and cache results.

### Behavior the official documentation does not describe

- Enumerations carry values the documentation omits (anime `tv_special`, `pv`, `cm`; manga `light_novel`, `on_hiatus`, `discontinued`; relation `other`). Value types such as `AnimeMediaType` keep any string MyAnimeList sends.
- Anime `statistics` counts arrive as strings; they decode as `Int`.
- A forum topic's `data` is an object and its `poll` a single object, not arrays.
- Search queries need at least 3 characters (HTTP 400 `invalid q`). An invalid client ID is HTTP 400, a missing one HTTP 403.

## Development

```bash
swift test
swiftlint lint --strict
```

## License

[MIT](LICENSE)
