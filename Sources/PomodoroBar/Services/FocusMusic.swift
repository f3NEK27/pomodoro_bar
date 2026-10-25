import AppKit

/// Плейлист Spotify для фокуса.
enum FocusMusic {
    static let playlistID = "6Cf1qYa6QwYB70TVDBIaE3"
    static let embedURL = URL(string: "https://open.spotify.com/embed/playlist/\(playlistID)?utm_source=generator&theme=0")!
    static let webURL = URL(string: "https://open.spotify.com/playlist/\(playlistID)")!
    private static let appURL = URL(string: "spotify:playlist:\(playlistID)")!

    /// Открыть плейлист в приложении Spotify, а если его нет — в браузере.
    static func openInSpotify() {
        if NSWorkspace.shared.urlForApplication(toOpen: appURL) != nil {
            NSWorkspace.shared.open(appURL)
        } else {
            NSWorkspace.shared.open(webURL)
        }
    }
}
