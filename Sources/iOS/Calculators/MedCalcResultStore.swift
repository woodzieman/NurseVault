import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// A single captured calculation result, shared across the app, widgets, and watch via the App Group.
struct CalculationResult: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var calculatorID: String
    var calculatorTitle: String
    var category: String
    /// The formatted result text, possibly multiple lines.
    var text: String
    var date: Date

    init(calculator: CalculatorInfo, text: String, date: Date = .now) {
        self.id = UUID()
        self.calculatorID = calculator.id
        self.calculatorTitle = calculator.title
        self.category = calculator.category
        self.text = text
        self.date = date
    }

    /// First line of the result, trimmed - suitable for widgets and complications.
    var firstLine: String {
        let line = text.components(separatedBy: .newlines).first ?? text
        return line.trimmingCharacters(in: .whitespaces)
    }
}

/// Persistent store for recent results and favorites, backed by the shared App Group container.
///
/// The app records results as the user calculates; widgets and the watch app read this store.
/// Mutations notify observers on the main thread and schedule a debounced widget reload.
final class ResultStore: @unchecked Sendable {
    static let shared = ResultStore()

    /// Posted on the main thread whenever results or favorites change.
    static let didChange = Notification.Name("MedCalcResultStoreDidChange")

    static let appGroupID = "group.com.josephwoods.nursevault"
    private static let resultsKey = "medcalc.recentResults"
    private static let favoritesKey = "medcalc.favorites"
    private static let maxResults = 100

    private let lock = NSLock()
    private let defaults: UserDefaults
    private var storedResults: [CalculationResult] = []
    private var storedFavorites: [String] = []
    private var reloadWorkItem: DispatchWorkItem?

    private init() {
        // Fall back to standard defaults if the App Group suite is unavailable (e.g. unsigned dev builds).
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
    }

    // MARK: - Recent results

    var results: [CalculationResult] {
        lock.lock()
        defer { lock.unlock() }
        return storedResults
    }

    /// Records a calculation result. Skips prompts/invalid output and rapid re-records of an unchanged value.
    func record(calculator: CalculatorInfo, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isRecordable(trimmed) else { return }

        lock.lock()
        if let latest = storedResults.first,
           latest.calculatorID == calculator.id,
           latest.text == trimmed,
           Date.now.timeIntervalSince(latest.date) < 60 {
            lock.unlock()
            return
        }
        var updated = [CalculationResult(calculator: calculator, text: trimmed)]
        updated.append(contentsOf: storedResults.filter { !($0.calculatorID == calculator.id && $0.text == trimmed) })
        storedResults = Array(updated.prefix(Self.maxResults))
        persistLocked()
        lock.unlock()

        notifyChange()
    }

    // MARK: - Favorites

    var favorites: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storedFavorites
    }

    func isFavorite(_ calculatorID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storedFavorites.contains(calculatorID)
    }

    func toggleFavorite(_ calculatorID: String) {
        lock.lock()
        if let index = storedFavorites.firstIndex(of: calculatorID) {
            storedFavorites.remove(at: index)
        } else {
            storedFavorites.append(calculatorID)
        }
        persistLocked()
        lock.unlock()

        notifyChange()
    }

    /// Favorites resolved to catalog entries, in the order they were starred.
    func favoriteCalculators() -> [CalculatorInfo] {
        favorites.compactMap { MedCalcCatalog.calculator(withID: $0) }
    }

    /// The most recent recorded result for a calculator, if any.
    func latestResult(for calculatorID: String) -> CalculationResult? {
        results.first { $0.calculatorID == calculatorID }
    }

    // MARK: - Persistence

    private func loadLocked() {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Self.resultsKey),
           let decoded = try? decoder.decode([CalculationResult].self, from: data) {
            storedResults = decoded
        }
        if let ids = defaults.stringArray(forKey: Self.favoritesKey) {
            storedFavorites = ids
        }
    }

    private func persistLocked() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(storedResults) {
            defaults.set(data, forKey: Self.resultsKey)
        }
        defaults.set(storedFavorites, forKey: Self.favoritesKey)
    }

    // MARK: - Change propagation

    private func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.didChange, object: nil)
            self.scheduleWidgetReload()
        }
    }

    /// Debounced so typing in the app doesn't burn the daily widget reload budget on every keystroke.
    private func scheduleWidgetReload() {
        lock.lock()
        reloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.triggerWidgetReload()
        }
        reloadWorkItem = workItem
        lock.unlock()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    #if canImport(WidgetKit)
    private func triggerWidgetReload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    #else
    private func triggerWidgetReload() {}
    #endif

    // MARK: - Recordability

    /// Filters out "not yet valid" prompts so widgets never show input placeholders.
    static func isRecordable(_ text: String) -> Bool {
        if text.isEmpty { return false }
        let lower = text.lowercased()
        let blockers = [
            "enter valid", "enter ", "not yet implemented",
            "use only", "no data", "provide ", "select ",
        ]
        return !blockers.contains { lower.contains($0) }
    }
}
