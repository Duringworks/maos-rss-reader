import Foundation
import SwiftData

actor RSSFeedService {
    // 1. Ubah parameter pertama untuk menerima PersistentIdentifier, bukan objek RSSFeed langsung
    func fetchAndRefresh(feedID: PersistentIdentifier, contextModelContainer: ModelContainer) async {
        let backgroundContext = ModelContext(contextModelContainer)
        
        // 2. Ambil objek feed yang valid di dalam background context menggunakan ID-nya
        guard let backgroundFeed = backgroundContext.model(for: feedID) as? RSSFeed else { return }
        
        // 3. Gunakan URL dari objek feed yang sudah aman di background thread
        guard let url = URL(string: backgroundFeed.url) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Parsing XML tidak butuh MainActor: kerjakan langsung di actor ini (background)
            // agar UI utama tetap responsif saat me-refresh banyak feed sekaligus.
            let parser = NativeRSSParser()
            let rawArticles = parser.parse(data: data)
            
            // Bangun Set dari ID artikel yang sudah ada sekali saja, alih-alih melakukan
            // satu query SwiftData per artikel (jauh lebih cepat untuk feed dengan banyak item).
            let existingIDs = Set(backgroundFeed.articles.map { $0.id })
            
            for raw in rawArticles {
                let articleID = raw.link.isEmpty ? raw.title : raw.link
                guard !existingIDs.contains(articleID) else { continue }
                
                let newArticle = RSSArticle(
                    id: articleID,
                    title: raw.title,
                    link: raw.link,
                    summary: raw.summary,
                    publishDate: raw.pubDate
                )
                backgroundFeed.articles.append(newArticle)
            }
            try backgroundContext.save()
        } catch {
            print("Error parsing feed: \(error)")
        }
    }
}
