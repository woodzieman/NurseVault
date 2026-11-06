import Foundation
import Observation

private struct ManifestResponse: Decodable {
    let calculators: [ClinicalCalculator]
}

@MainActor
@Observable
public final class ClinicalCalculatorCatalog {
    public var calculators: [ClinicalCalculator] = []
    public var isLoading = false
    public var error: Error?

    public static let shared = ClinicalCalculatorCatalog()

    private init() {}

    public func load() {
        isLoading = true

        // The manifest.json is at Resources/ClinicalCalculators/Data/manifest.json in the app bundle
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "Resources/ClinicalCalculators/Data") else {
            self.error = NSError(domain: "ClinicalCalculatorCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "manifest.json not found"])
            self.isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ManifestResponse.self, from: data)
            self.calculators = decoded.calculators
        } catch {
            self.error = error
        }
        self.isLoading = false
    }
}
