import Foundation

/// Dữ liệu mẫu (fixtures) dùng chung cho các unit test.
enum TestFixtures {

    // MARK: - Search response

    static let searchResponseJSON = """
    {
      "kind": "youtube#searchListResponse",
      "etag": "test-etag",
      "nextPageToken": "CAUQAA",
      "regionCode": "US",
      "pageInfo": {
        "totalResults": 1000000,
        "resultsPerPage": 20
      },
      "items": [
        {
          "kind": "youtube#searchResult",
          "etag": "item-etag",
          "id": {
            "kind": "youtube#video",
            "videoId": "abc123"
          },
          "snippet": {
            "publishedAt": "2025-01-15T10:00:00Z",
            "channelId": "UC123",
            "title": "Phonk Test Song",
            "description": "Một bài hát phonk để test.",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/abc123/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/abc123/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/abc123/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "Test Channel"
          }
        },
        {
          "kind": "youtube#searchResult",
          "etag": "item-etag-2",
          "id": {
            "kind": "youtube#video",
            "videoId": "def456"
          },
          "snippet": {
            "publishedAt": "2025-02-01T08:30:00Z",
            "channelId": "UC456",
            "title": "Chill Lofi Beat",
            "description": "",
            "thumbnails": {
              "medium": {
                "url": "https://i.ytimg.com/vi/def456/mqdefault.jpg"
              }
            },
            "channelTitle": "Lofi Channel"
          }
        }
      ]
    }
    """

    static var searchResponseData: Data { Data(searchResponseJSON.utf8) }

    // MARK: - Videos response (chi tiết)

    static let videosResponseJSON = """
    {
      "kind": "youtube#videoListResponse",
      "etag": "videos-etag",
      "pageInfo": {
        "totalResults": 1,
        "resultsPerPage": 1
      },
      "items": [
        {
          "kind": "youtube#video",
          "etag": "video-etag",
          "id": "abc123",
          "snippet": {
            "publishedAt": "2025-01-15T10:00:00Z",
            "channelId": "UC123",
            "title": "Phonk Test Song",
            "description": "Một bài hát phonk để test.",
            "thumbnails": {
              "high": {
                "url": "https://i.ytimg.com/vi/abc123/hqdefault.jpg"
              },
              "maxres": {
                "url": "https://i.ytimg.com/vi/abc123/maxresdefault.jpg"
              }
            },
            "channelTitle": "Test Channel"
          },
          "contentDetails": {
            "duration": "PT4M13S",
            "dimension": "2d",
            "definition": "hd",
            "caption": "false",
            "licensedContent": true
          },
          "statistics": {
            "viewCount": "1234567",
            "likeCount": "45678",
            "favoriteCount": "0",
            "commentCount": "2345"
          }
        }
      ]
    }
    """

    static var videosResponseData: Data { Data(videosResponseJSON.utf8) }

    // MARK: - Error response (quota exceeded)

    static let quotaErrorJSON = """
    {
      "error": {
        "code": 403,
        "message": "The request cannot be completed because you have exceeded your quota.",
        "errors": [
          {
            "message": "The request cannot be completed because you have exceeded your quota.",
            "domain": "youtube.quota",
            "reason": "quotaExceeded"
          }
        ]
      }
    }
    """

    static var quotaErrorData: Data { Data(quotaErrorJSON.utf8) }

    // MARK: - JSON không hợp lệ

    static let invalidJSONData = Data("không phải json".utf8)
}
