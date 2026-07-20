import SwiftUI
import SwiftData

struct MainSplitView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RSSFeed.title) private var feeds: [RSSFeed]
    
    // Cukup gunakan selectedFeed bawaan. Default nil berarti "All Feeds" terpilih
    @State private var selectedFeed: RSSFeed? = nil
    @State private var selectedArticle: RSSArticle? = nil
    @State private var showingAddFeedSheet = false
    
    // Bind ke AppStorage yang sama dengan file App utama
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedFeed) {
                
                // 1. Menu "All Feeds": satu tempat berisi ringkasan semua feed yang ditambahkan
                //    (5 artikel terbaru per feed + tombol "Read more from this feed")
                Section {
                    NavigationLink(value: RSSFeed?.none) {
                        Label("All Feeds", systemImage: "tray.full")
                    }
                }
                
                Section("My Feeds") {
                    ForEach(feeds) { feed in
                        // 2. Cast value ke 'RSSFeed?' agar tipe datanya cocok dengan selection milik List
                        NavigationLink(value: feed as RSSFeed?) {
                            Label(feed.title, systemImage: "dot.radiowaves.up.forward")
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteFeed(feed)
                            } label: {
                                Label("Delete Feed", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .toolbar {
                // Toolbar 1: Tombol Tambah Feed
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFeedSheet.toggle()
                    } label: {
                        Label("Add Feed", systemImage: "plus")
                    }
                }
                
                // Toolbar 2: Theme Switcher
                ToolbarItem(placement: .automatic) {
                    Picker(selection: $selectedTheme, label: Image(systemName: themeIcon)) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 45)
                }
            }
        } content: {
            // 3. Langsung masukkan selectedFeed tanpa computed binding
            ArticleListView(
                feed: selectedFeed,
                selectedFeed: $selectedFeed,
                selectedArticle: $selectedArticle
            )
        } detail: {
            ArticleDetailView(article: selectedArticle)
        }
        .sheet(isPresented: $showingAddFeedSheet) {
            AddFeedView()
        }
    }
    
    // Menghapus feed dengan aman: bersihkan selection dulu agar sidebar/detail
    // tidak menunjuk ke objek yang sudah dihapus (mencegah crash & tampilan basi).
    private func deleteFeed(_ feed: RSSFeed) {
        if selectedFeed?.persistentModelID == feed.persistentModelID {
            selectedFeed = nil
            selectedArticle = nil
        }
        modelContext.delete(feed)
        try? modelContext.save()
    }
    
    // Helper untuk mengubah ikon toolbar sesuai tema yang aktif
    private var themeIcon: String {
        switch selectedTheme {
        case .system: return "laptopcomputer"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
