# Maos 📰

Maos is a **native macOS RSS reader** built entirely with **SwiftUI** and **SwiftData**. It lets you add your favorite RSS/Atom feeds, read articles in a three-pane layout similar to Mail.app, and mark articles as read or starred.

## ✨ Features

- **Add RSS/Atom feeds** — enter a feed URL, title, and category through a simple form.
- **Native RSS/Atom parser** — XML parsing is done directly with Foundation's `XMLParser` (no external dependencies), supporting both RSS 2.0 and Atom formats.
- **"All Feeds" overview** — shows the 5 latest articles from each feed, with a "Read more" option to view all articles from that feed.
- **Article search** — search by article title or summary content.
- **Feed refresh** — refresh a single feed or all feeds in parallel in the background (without blocking the UI).
- **Article detail in a WebView** — article content is rendered with `WKWebView`, with styling that adapts to light/dark mode plus loading and error indicators.
- **Read & starred status** — track read state and favorite (starred) articles per item.
- **System/Light/Dark theme** — switchable directly from the toolbar and persisted via `UserDefaults`.
- **Persistent local storage** — all feeds and articles are stored with SwiftData and remain available after the app is closed.

## 🖥️ Interface

Maos uses macOS's classic three-column `NavigationSplitView`:

1. **Sidebar** — list of added feeds (plus an "All Feeds" option showing a combined view of all feeds).
2. **Article List** — articles from the selected feed, with a search bar and refresh button.
3. **Article Detail** — full content of the selected article.

## 🏗️ Architecture & Project Structure

```
Maos/
├── MacRSSReaderApp.swift     # App entry point, sets up the SwiftData ModelContainer
├── RSSModels.swift           # Data models: RSSFeed & RSSArticle (SwiftData @Model)
├── RSSFeedService.swift      # Actor that fetches & refreshes feeds on a background thread
├── NativeRSSParser.swift     # Native XML parser (RSS 2.0 & Atom) using XMLParser
├── MainSplitView.swift       # Root view: 3-column NavigationSplitView + feed sidebar
├── AddFeedView.swift         # Form/sheet for adding a new feed
├── ArticleListView.swift     # Article list (per feed & "All Feeds" view)
├── ArticleDetailView.swift   # Article detail + WKWebView for rendering HTML content
├── AppTheme.swift            # Theme enum (System/Light/Dark)
└── Assets.xcassets/          # App icon & accent color
```

### Data Flow Overview

1. The user adds a feed via **AddFeedView** → it's saved as an `RSSFeed` in SwiftData.
2. **RSSFeedService** (an actor) fetches the feed's XML via `URLSession`, then parses it using **NativeRSSParser** on a background thread.
3. New articles (checked against existing ones by `id`/`link`) are saved as `RSSArticle` records related to the parent `RSSFeed` (cascade delete).
4. **MainSplitView**, **ArticleListView**, and **ArticleDetailView** display the data reactively using `@Query` and `@Environment(\.modelContext)`.

## 🧩 Data Models

- **RSSFeed** — `url` (unique), `title`, `category`, one-to-many relationship to `articles`.
- **RSSArticle** — `id` (unique, derived from link/title), `title`, `link`, `summary`, `publishDate`, `isRead`, `isStarred`.

## 🛠️ Tech Stack

| Component        | Technology                     |
|-------------------|--------------------------------|
| UI                | SwiftUI (`NavigationSplitView`) |
| Data Persistence  | SwiftData                      |
| Web Content       | WebKit (`WKWebView`)           |
| XML Parsing       | Foundation `XMLParser` (native, no third-party libraries) |
| Concurrency       | Swift Concurrency (`actor`, `async/await`, `TaskGroup`)   |
| Language          | Swift 5.0                      |
| Platform          | macOS                          |
| Bundle Identifier | `com.ffadilaputra.Maos`        |

## 🚀 Running the Project (Development)

1. Open `Maos.xcodeproj` in **Xcode**.
2. Select the `Maos` scheme and run it (`⌘R`) with the **My Mac** target.
3. Add your first feed via the **+** button in the sidebar toolbar, filling in Title, Feed URL, and Category.

## 📦 Building a Distributable .dmg

There are two common ways to package Maos as a `.dmg` you can share or distribute.

### Option A — Archive & Export via Xcode (recommended for signing/notarization)

1. In Xcode, select **Product → Archive** (make sure the scheme is set to **Release**, target **Any Mac / My Mac**).
2. Once archiving finishes, the **Organizer** window opens automatically. Select the new archive and click **Distribute App**.
3. Choose a distribution method:
   - **Direct Distribution** — for sharing outside the Mac App Store (requires a Developer ID certificate for notarization).
   - **Copy App** — exports the raw `.app` bundle without notarization (fine for personal/internal use).
4. Xcode will export the signed `Maos.app` to a folder of your choice.
5. Turn the exported `.app` into a `.dmg` using **Disk Utility** or the command line (see the `hdiutil` steps in Option B below).
6. If you distribute outside the App Store, notarize the `.dmg`/`.app` with `xcrun notarytool` so Gatekeeper doesn't block it on other Macs.

### Option B — Command Line (xcodebuild + hdiutil)

```bash
# 1. Build a Release archive
xcodebuild -project Maos.xcodeproj \
  -scheme Maos \
  -configuration Release \
  -archivePath build/Maos.xcarchive \
  archive

# 2. Export the .app from the archive
#    (exportOptions.plist should specify method: "developer-id" or "mac-application"
#    depending on how you plan to distribute it)
xcodebuild -exportArchive \
  -archivePath build/Maos.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist exportOptions.plist

# 3. Create a staging folder with the app and a shortcut to /Applications
mkdir -p build/dmg
cp -R build/export/Maos.app build/dmg/
ln -s /Applications build/dmg/Applications

# 4. Create the .dmg from that folder
hdiutil create -volname "Maos" \
  -srcfolder build/dmg \
  -ov -format UDZO \
  build/Maos.dmg
```

Notes:
- `exportOptions.plist` is a small plist you create once, specifying the export `method` (e.g. `developer-id`), your Team ID, and signing options. Xcode can generate a starting template for you the first time you use **Distribute App**.
- For a more polished-looking `.dmg` (custom background, icon layout), you can use the open-source [`create-dmg`](https://github.com/create-dmg/create-dmg) tool instead of raw `hdiutil`:
  ```bash
  brew install create-dmg
  create-dmg \
    --volname "Maos" \
    --window-size 500 300 \
    --icon "Maos.app" 125 150 \
    --app-drop-link 375 150 \
    "build/Maos.dmg" \
    "build/export/Maos.app"
  ```
- If the `.dmg` is meant for distribution outside your own Mac, notarize it first (`xcrun notarytool submit build/Maos.dmg --keychain-profile "your-profile" --wait`) and staple the ticket (`xcrun stapler staple build/Maos.dmg`), or Gatekeeper will flag it as from an "unidentified developer" on other machines.

## 📋 Requirements

- macOS with a recent version of Xcode that supports SwiftData and Swift Concurrency.
- An internet connection to fetch and refresh RSS feeds.
- A valid Apple Developer ID (free or paid) if you plan to sign/notarize the app for distribution.

## 📌 Development Notes

- Some code comments were originally written in Indonesian by the developer as implementation notes (e.g. reasons for using a SwiftData background context, why `existingIDs` is cached for performance, etc.). This English README summarizes the project in English regardless.
- The parser supports common RSS tags (`item`, `title`, `link`, `description`, `pubDate`) as well as Atom tags (`entry`, `summary`, `content`, `published`/`updated`).
