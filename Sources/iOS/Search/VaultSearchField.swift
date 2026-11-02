import SwiftUI

/// A rounded, sidebar-style search field, shared by the vault sidebar and the
/// search results screen.
///
/// It replaces the system `.searchable` field on iOS: in the new design the
/// system field floats in a Liquid Glass container at the *bottom* of the
/// sidebar, where it covers the list rows behind it.
struct VaultSearchField: View {
    @Binding var text: String
    /// Focus the field (and raise the keyboard) when it appears. The results
    /// screen uses this so typing continues there after the sidebar's field
    /// slides off screen.
    var focusesOnAppear = false

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $text)
                .focused($focused)
                .submitLabel(.search)
                .onSubmit { focused = false }
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: .capsule)
        .accessibilityIdentifier("global-search")
        .onAppear {
            if focusesOnAppear {
                focused = true
            }
        }
    }
}
