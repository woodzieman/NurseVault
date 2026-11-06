#!/bin/bash
# Post-build: copy ClinicalCalculators Data folder into the app bundle
# Called by Fastfile upload lane after build_app but before upload

# Determine working directory
WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$WORK_DIR/Sources/iOS/Resources/ClinicalCalculators/Data"
OUTPUT_DIR="$WORK_DIR/build/export/fastlane"

if [ ! -d "$SRC_DIR" ]; then
  echo "WARNING: ClinicalCalculators source not found"
  exit 0
fi

# The build produces a .app (not .ipa) in the output directory
APP_BUNDLE="$OUTPUT_DIR/NurseVault.app"
if [ ! -d "$APP_BUNDLE" ]; then
  echo "WARNING: App bundle not found at $APP_BUNDLE"
  # Try IPA (in case the build still produces an IPA)
  IPA_FILE="$OUTPUT_DIR/NurseVault.ipa"
  ARCHIVE_DIR="$OUTPUT_DIR/.NurseVault_extracted"
  rm -rf "$ARCHIVE_DIR"
  unzip -q "$IPA_FILE" -d "$ARCHIVE_DIR" 2>/dev/null
  APP_BUNDLE="$ARCHIVE_DIR/Payload/NurseVault.app"
  if [ ! -d "$APP_BUNDLE" ]; then
    echo "WARNING: App bundle not found in either .app or IPA"
    exit 0
  fi
  echo "Working with extracted IPA"
fi

# Copy the Data folder contents to Resources/ClinicalCalculators/Data/
RES_DIR="$APP_BUNDLE/Resources/ClinicalCalculators/Data"
mkdir -p "$RES_DIR"
cp "$SRC_DIR"/* "$RES_DIR/" 2>/dev/null
COUNT=$(ls "$RES_DIR" 2>/dev/null | wc -l)
echo "Copied $COUNT ClinicalCalculators files to bundle"

# If we extracted from an IPA, re-compress it
if [ -d "$OUTPUT_DIR/.NurseVault_extracted" ]; then
  cd "$OUTPUT_DIR/.NurseVault_extracted"
  zip -r -q "$OUTPUT_DIR/NurseVault.ipa" Payload 2>/dev/null
  rm -rf "$OUTPUT_DIR/.NurseVault_extracted"
  echo "IPA re-compressed"
fi
