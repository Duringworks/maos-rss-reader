import SwiftUI
import SwiftData

@main
struct MacRSSReaderApp: App {
    // Menyimpan pilihan tema secara lokal di UserDefaults Mac
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([RSSFeed.self, RSSArticle.self]) // <- Hapus "[cite: 10]" di sini
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .preferredColorScheme(selectedTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            SidebarCommands()
        }
    }
}
