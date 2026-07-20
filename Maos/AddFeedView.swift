import SwiftUI
import SwiftData

struct AddFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var urlString = "https://"
    @State private var category = "Tech"
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New RSS Feed").font(.headline)
            Form {
                TextField("Feed Title:", text: $title)
                TextField("Feed URL:", text: $urlString)
                TextField("Category:", text: $category)
            }.formStyle(.grouped)
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button {
                    saveFeed()
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Save Feed")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty ||
                          urlString.trimmingCharacters(in: .whitespaces).isEmpty ||
                          isSaving)
            }
        }
        .padding()
        .frame(width: 400, height: 220)
    }
    
    // Di dalam AddFeedView.swift -> fungsi saveFeed()[cite: 18]
    private func saveFeed() {
        isSaving = true
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let newFeed = RSSFeed(url: cleanURL, title: cleanTitle, category: cleanCategory.isEmpty ? "Uncategorized" : cleanCategory)
        modelContext.insert(newFeed)
        
        // PENTING: Lakukan save dulu agar temporaryIdentifier berubah menjadi Permanent ID
        try? modelContext.save()
        
        let feedID = newFeed.persistentModelID
        
        Task {
            let service = RSSFeedService()
            await service.fetchAndRefresh(feedID: feedID, contextModelContainer: modelContext.container)
            isSaving = false
            dismiss()
        }
    }
}
