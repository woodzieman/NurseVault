import AppIntents

/// Entity query backing the configurable favorites widgets.
struct CalculatorEntityQuery: EntityQuery {
    typealias Entity = CalculatorEntity

    init() {}

    func entities(for identifiers: [String]) async throws -> [CalculatorEntity] {
        identifiers.compactMap { CalculatorEntity(id: $0) }
    }

    func suggestedEntities() async throws -> [CalculatorEntity] {
        MedCalcCatalog.all.map(CalculatorEntity.init)
    }
}

/// An App Intents entity representing one clinical calculator, used by the configurable widgets.
struct CalculatorEntity: AppEntity {
    typealias ValueType = Self
    typealias Specification = EmptyResolverSpecification<Self>

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Clinical Calculators")
    }

    let id: String
    let title: String
    let category: String

    init?(id: String) {
        guard let calculator = MedCalcCatalog.calculator(withID: id) else { return nil }
        self.id = calculator.id
        self.title = calculator.title
        self.category = calculator.category
    }

    init(_ calculator: CalculatorInfo) {
        self.id = calculator.id
        self.title = calculator.title
        self.category = calculator.category
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(category)")
    }

    static var defaultQuery: CalculatorEntityQuery {
        CalculatorEntityQuery()
    }
}

/// User configuration for the favorites widget: which calculators to pin.
struct MedCalcFavoritesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Favorite Calculators"
    static let description = IntentDescription("Choose which calculators to pin to the MedCalc widget.")

    @Parameter(title: "Calculators", default: [])
    var calculators: [CalculatorEntity]

    init() {}
}
