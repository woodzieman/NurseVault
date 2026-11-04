import Foundation
import Observation
import SwiftUI

/// Minimal UI state for an in-flight document import.
@MainActor
@Observable
final class BookImportState {
    var isActive = false
    var fileName: String? = nil
    var progress: Double? = nil
    var error: String? = nil

    func begin(_ name: String) {
        isActive = true
        fileName = name
        progress = 0
        error = nil
    }

    func update(_ fraction: Double) {
        progress = min(max(fraction, 0), 1)
    }

    func finish() {
        isActive = false
        progress = 1
    }

    func fail(_ message: String) {
        isActive = false
        error = message
    }
}
