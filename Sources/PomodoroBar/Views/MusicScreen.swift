import SwiftUI
import WebKit

/// Экран музыки: виджет плейлиста Spotify и кнопка открыть его в приложении.
struct MusicScreen: View {
    private let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [spotifyGreen.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Музыка для фокуса")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                    Button {
                        FocusMusic.openInSpotify()
                    } label: {
                        Label("Открыть в Spotify", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(spotifyGreen)
                    .controlSize(.large)
                }

                SpotifyEmbed(url: FocusMusic.embedURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("В виджете без входа в Spotify играют отрывки по 30 секунд. Полностью плейлист играет в приложении Spotify. В настройках можно включить автозапуск плейлиста при старте фокуса.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
        }
    }
}

/// Тот же виджет, что даёт Spotify для сайтов (iframe), только внутри окна приложения.
private struct SpotifyEmbed: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}
}
