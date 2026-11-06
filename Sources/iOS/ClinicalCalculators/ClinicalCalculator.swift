import Foundation

public struct ClinicalCalculator: Identifiable, Codable, Hashable {
    public let id: String // Using the filename as ID
    public let title: String
    public let fileName: String
    public let merckPage: String
    public let widgetUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case file
        case merckPage = "merck_page"
        case widgetUrl = "widget_url"
    }

    public init(id: String, title: String, fileName: String, merckPage: String, widgetUrl: String) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.merckPage = merckPage
        self.widgetUrl = widgetUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.fileName = try container.decode(String.self, forKey: .file)
        self.merckPage = try container.decode(String.self, forKey: .merckPage)
        self.widgetUrl = try container.decode(String.self, forKey: .widgetUrl)
        self.id = fileName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(fileName, forKey: .file)
        try container.encode(merckPage, forKey: .merckPage)
        try container.encode(widgetUrl, forKey: .widgetUrl)
    }
}
