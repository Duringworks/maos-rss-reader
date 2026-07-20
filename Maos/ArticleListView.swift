import SwiftUI
import SwiftData

struct ArticleListView: View {
    var feed: RSSFeed?
    @Binding var selectedFeed: RSSFeed?
    @Binding var selectedArticle: RSSArticle? // Kembali menggunakan RSSArticle? sesuai kode aslimu
    
    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshing = false
    @State private var searchText = ""
    
    @Query(sort: \RSSFeed.title) private var allFeeds: [RSSFeed]
    
    var body: some View {
        // SATU LIST TUNGGAL YANG STABIL UNTUK MENJAGA NAVIGASI macOS
        List(selection: $selectedArticle) {
            if let currentFeed = feed {
                // ==========================================
                // 1. TAMPILAN SINGLE FEED (DALAM LIST UTAMA)
                // ==========================================
                let filtered = filteredArticles(from: currentFeed.articles)
                ForEach(filtered) { article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article)
                    }
                }
            } else {
                // ==========================================
                // 2. TAMPILAN ALL ARTICLES (DALAM LIST UTAMA)
                // ==========================================
                if allFeeds.isEmpty {
                    Text("No Feeds Found. Add a feed from the sidebar to get started.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    // MEMAKAI SUB-VIEW UNTUK MENJAGA SINKRONISASI SWIFTDATA
                    ForEach(allFeeds) { singleFeed in
                        FeedSectionView(
                            feed: singleFeed,
                            searchText: searchText,
                            selectedFeed: $selectedFeed
                        )
                    }
                }
            }
        }
        .navigationTitle(feed?.title ?? "All Feeds")
        .searchable(text: $searchText, prompt: "Search articles...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    refreshFeed()
                } label: {
                    if isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
    }
    
    private func filteredArticles(from articles: [RSSArticle]) -> [RSSArticle] {
        let sorted = articles.sorted { $0.publishDate > $1.publishDate }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func refreshFeed() {
        isRefreshing = true
        let container = modelContext.container
        let targetFeedID = feed?.persistentModelID
        let feedsToRefresh = allFeeds.map { $0.persistentModelID }
        
        Task {
            let service = RSSFeedService()
            if let feedID = targetFeedID {
                await service.fetchAndRefresh(feedID: feedID, contextModelContainer: container)
            } else {
                await withTaskGroup(of: Void.self) { group in
                    for id in feedsToRefresh {
                        group.addTask {
                            await service.fetchAndRefresh(feedID: id, contextModelContainer: container)
                        }
                    }
                }
            }
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// ==============================================================
// SUB-VIEW BARU: Menjamin Data Relasi SwiftData Tetap Ter-observasi
// ==============================================================
struct FeedSectionView: View {
    let feed: RSSFeed
    var searchText: String
    @Binding var selectedFeed: RSSFeed?
    
    var body: some View {
        let bindableFeed = feed
        
        Section {
            let sortedArticles = bindableFeed.articles.sorted { $0.publishDate > $1.publishDate }
            
            // Menerapkan pencarian teks juga di halaman All Articles
            let filtered = searchText.isEmpty ? sortedArticles : sortedArticles.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText)
            }
            let previewArticles = Array(filtered.prefix(5))
            
            if previewArticles.isEmpty {
                if searchText.isEmpty {
                    Text("No articles available in this feed.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    EmptyView()
                }
            } else {
                ForEach(previewArticles) { article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article)
                    }
                }
                
                if filtered.count > 5 {
                    Button {
                        withAnimation(.easeInOut) {
                            selectedFeed = bindableFeed
                        }
                    } label: {
                        HStack {
                            Text("Read more from \(bindableFeed.title)...")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.accentColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderless)
                }
            }
        } header: {
            let hasContent = !searchText.isEmpty ?
                bindableFeed.articles.contains(where: { $0.title.localizedCaseInsensitiveContains(searchText) }) : true
            
            if hasContent {
                HStack {
                    Text(bindableFeed.title)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(bindableFeed.articles.count) articles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct ArticleRow: View {
    let article: RSSArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if !article.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(.body)
                        .fontWeight(article.isRead ? .regular : .semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(article.publishDate.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if article.isStarred {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
