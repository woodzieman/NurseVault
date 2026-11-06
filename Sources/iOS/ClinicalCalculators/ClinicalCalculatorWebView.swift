import SwiftUI
import WebKit

struct ClinicalCalculatorWebView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        // The .htm files are at Resources/ClinicalCalculators/Data/*.htm in the app bundle
                if let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".htm", with: ""), withExtension: "htm", subdirectory: "Resources/ClinicalCalculators/Data") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            // Fallback to looking for .html if .htm doesn't match
            if let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".htm", with: ""), withExtension: "html", subdirectory: nil) {
                webView.loadFileURL(url, allowingReadAccessTo: url)
            }
        }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
