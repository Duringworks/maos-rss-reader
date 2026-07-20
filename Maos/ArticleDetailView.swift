import SwiftUI
import WebKit

struct ArticleDetailView: View {
    var article: RSSArticle?
    @Environment(\.colorScheme) private var colorScheme
    
    // State untuk memantau status loading dan error dari WebView
    @State private var isLoading = true
    @State private var isError = false

    var body: some View {
        Group {
            if let article = article {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.title).font(.title).bold()
                        HStack {
                            Text(article.publishDate.formatted(date: .long, time: .shortened)).foregroundColor(.secondary)
                            Spacer()
                            Button { article.isStarred.toggle() } label: {
                                Label(article.isStarred ? "Starred" : "Star", systemImage: article.isStarred ? "star.fill" : "star")
                                    .foregroundColor(article.isStarred ? .yellow : .secondary)
                            }.buttonStyle(.plain)
                            Button { article.isRead.toggle() } label: {
                                Label(article.isRead ? "Mark Unread" : "Mark Read", systemImage: article.isRead ? "circle" : "circle.fill")
                            }.buttonStyle(.plain)
                            if let url = URL(string: article.link) {
                                Link(destination: url) { Image(systemName: "safari").foregroundColor(.accentColor) }
                            }
                        }
                    }
                    .padding([.top, .horizontal])
                    
                    Divider()
                    
                    // PERBAIKAN: Langsung cek .isEmpty tanpa 'if let' karena tipe datanya non-optional String
                    if !article.summary.isEmpty {
                        ZStack {
                            // Tampilan Utama WebView
                            ContextWebView(htmlContent: article.summary, isDark: colorScheme == .dark, isLoading: $isLoading, isError: $isError)
                                .opacity(isLoading || isError ? 0 : 1)
                            
                            // 1. Tampilan Sedang Memuat Data
                            if isLoading && !isError {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                    Text("Sedang memuat data...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            
                            // 2. Tampilan Jika Gagal Memuat (Error Fetch)
                            if isError {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.orange)
                                    Text("Gambar atau konten gagal di-fetch.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .onAppear {
                            isLoading = true
                            isError = false
                            article.isRead = true
                        }
                        .onChange(of: article.id) {
                            isLoading = true
                            isError = false
                        }
                        
                    } else {
                        // 3. Tampilan Jika Konten/Gambar Tidak Tersedia
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Gambar dan deskripsi tidak tersedia.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                ContentUnavailableView("No Article Selected", systemImage: "newspaper", description: Text("Select an article from the list."))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ContextWebView: NSViewRepresentable {
    let htmlContent: String
    let isDark: Bool
    @Binding var isLoading: Bool
    @Binding var isError: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let styledHtml = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                font-size: 14px; 
                line-height: 1.6; 
                color: {color}; 
                margin: 16px 20px;
                word-wrap: break-word;
            }
            a { color: #007aff; text-decoration: none; }
            img { 
                max-width: 100% !important; 
                height: auto !important; 
                border-radius: 8px; 
                margin-bottom: 12px;
                display: block;
            }
            .detail__media, .pic, figure, center {
                max-width: 100% !important;
                margin: 0 0 12px 0 !important;
                padding: 0 !important;
            }
        </style>
        </head>
        <body>\(htmlContent)</body>
        </html>
        """
        
        let finalHtml = styledHtml.replacingOccurrences(of: "{color}", with: isDark ? "#ffffff" : "#222222")
        nsView.loadHTMLString(finalHtml, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ContextWebView
        
        init(_ parent: ContextWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.isError = true
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.isError = true
            }
        }
    }
}
