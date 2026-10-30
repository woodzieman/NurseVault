import Foundation

/// Deep links of the form `medcalc://calculator/<calculatorID>`.
///
/// Used by widgets (Link), the watch app (openURL), and handled by the iPhone app via onOpenURL.
enum MedCalcDeepLink {
    static let scheme = "nursevault"

    static func url(calculatorID: String) -> URL? {
        URL(string: "\(scheme)://calculator/\(calculatorID)")
    }

    static func calculatorID(from url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), scheme == Self.scheme else { return nil }
        // medcalc://calculator/<id>  -> host "calculator", path "/<id>"
        let host = url.host?.lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if host == "calculator", !path.isEmpty {
            return path
        }
        // Tolerate the looser medcalc://<id> form.
        if let host, !host.isEmpty, host != "calculator" {
            return host
        }
        return nil
    }
}
