import Foundation
import SwiftData

@Model
final class RSSFeed {
    @Attribute(.unique) var url: String
    var title: String
    var category: String
    @Relationship(deleteRule: .cascade) var articles: [RSSArticle] = []
    
    init(url: String, title: String, category: String = "Uncategorized") {
        self.url = url
        self.title = title
        self.category = category
    }
}

@Model
final class RSSArticle {
    @Attribute(.unique) var id: String
    var title: String
    var link: String
    var summary: String
    var publishDate: Date
    var isRead: Bool
    var isStarred: Bool
    
    init(id: String, title: String, link: String, summary: String, publishDate: Date, isRead: Bool = false, isStarred: Bool = false) {
        self.id = id
        self.title = title
        self.link = link
        self.summary = summary
        self.publishDate = publishDate
        self.isRead = isRead
        self.isStarred = isStarred
    }
}
