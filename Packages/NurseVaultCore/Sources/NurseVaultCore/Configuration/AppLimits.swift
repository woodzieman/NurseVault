import Foundation

/// Application-wide limits and configuration constants.
public enum AppLimits {
    /// Maximum file size allowed for import (48 MB).
    public static let maxFileSize: Int = 48 * 1024 * 1024
    
    /// Maximum PDF size to search in bytes (16 MB).
    public static let maxPDFSearchSize: Int = 16 * 1024 * 1024
    
    /// Maximum number of import attempts before giving up.
    public static let maxImportAttempts: Int = 1_000
    
    /// Number of parallel workers for content scanning operations.
    public static let scanWorkers: Int = 4
    
    /// Maximum entries to keep in the content cache.
    public static let contentCacheLimit: Int = 100
    
    /// Minimum query length required for content search (characters).
    public static let minContentSearchLength: Int = 2
    
    /// Timeout for item provider loading operations (seconds).
    public static let itemProviderTimeout: TimeInterval = 30.0
    
    /// Delay before retrying failed save operation (seconds).
    public static let saveRetryDelay: TimeInterval = 0.5
    
    /// Maximum number of entries in the search cache.
    public static let maxSearchCacheEntries: Int = 200
    
    /// Maximum total size for search cache in bytes (~500 MB).
    public static let maxSearchCacheBytes: Int = 500 * 1024 * 1024
}

/// Logging subsystem and categories for structured logging.
enum AppLogging {
    static let subsystem = "com.josephwoods.nursevault"
    
    enum Category {
        static let library = "Library"
        static let search = "Search"
        static let importExport = "ImportExport"
        static let watchReference = "WatchReference"
        static let sync = "Sync"
    }
}
