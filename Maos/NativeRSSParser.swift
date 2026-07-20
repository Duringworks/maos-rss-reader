import Foundation

final class NativeRSSParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentSummary = ""
    private var currentPubDate = ""
    
    var parsedArticles: [(title: String, link: String, summary: String, pubDate: Date)] = []
    
    // Formatter dibuat sekali saja (bukan per-artikel) agar parsing feed besar jauh lebih cepat.
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "E, dd MMM yyyy HH:mm:ss Z",
            "E, dd MMM yyyy HH:mm:ss zzzz",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }
    }()
    
    func parse(data: Data) -> [(title: String, link: String, summary: String, pubDate: Date)] {
        parsedArticles.removeAll()
        parsedArticles.reserveCapacity(64)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        parser.parse()
        return parsedArticles
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item" || currentElement == "entry" {
            currentTitle = ""
            currentLink = ""
            currentSummary = ""
            currentPubDate = ""
        }
        if elementName == "link", let href = attributeDict["href"] {
                currentLink = href
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        switch currentElement {
        case "title": currentTitle += trimmed
        case "link": currentLink += trimmed
        case "description", "summary", "content": currentSummary += trimmed
        case "pubDate", "published", "updated": currentPubDate += trimmed
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            var parsedDate = Date()
            for formatter in Self.dateFormatters {
                if let date = formatter.date(from: currentPubDate) {
                    parsedDate = date
                    break
                }
            }
            
            parsedArticles.append((
                title: currentTitle.isEmpty ? "Untitled Article" : currentTitle,
                link: currentLink,
                summary: currentSummary,
                pubDate: parsedDate
            ))
        }
    }
}
