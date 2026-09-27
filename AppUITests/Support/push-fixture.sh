#!/bin/bash
# Pre-test: put the import-test fixture where the app's file importer can
# find it — the simulator's device-level ~/Documents, or the Mac's
# ~/Documents when running the macOS UI tests.
set -euo pipefail

FIXTURE="$SRCROOT/AppUITests/Support/Amiodarone Dosing.pdf"

DEVICE=$(xcrun simctl list devices booted 2>/dev/null \
    | grep -m1 -E "iPhone|iPad" | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/' || true)

if [ -n "${DEVICE:-}" ]; then
    # Remove first: the simulator's file indexer only notices a *new* file
    # (pushing over an existing one is a no-op for it), and the document
    # picker lists the Documents folder from that index.
    # (spawn runs without a shell, so use $HOME rather than ~)
    xcrun simctl spawn "$DEVICE" rm "$HOME/Documents/Amiodarone Dosing.pdf" 2>/dev/null || true
    if xcrun simctl push "$DEVICE" "$FIXTURE" ~/Documents/"Amiodarone Dosing.pdf"; then
        echo "Pushed 'Amiodarone Dosing.pdf' to simulator $DEVICE"
    else
        echo "warning: could not push fixture; continuing"
    fi
else
    cp "$FIXTURE" "$HOME/Documents/Amiodarone Dosing.pdf"
    echo "Copied 'Amiodarone Dosing.pdf' to Mac ~/Documents"
fi
