import SwiftUI

/// Cross-platform keyboard helper.
///
/// `Sources/iOS` compiles for both iOS and macOS (multiplatform target), but
/// `keyboardType(_:)` is iOS-only. Call sites use `decimalPadKeyboard()`
/// instead so the macOS build compiles; on macOS it is a no-op.
extension View {
    /// Numeric keypad on iOS; a no-op on macOS.
    @ViewBuilder
    func decimalPadKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
