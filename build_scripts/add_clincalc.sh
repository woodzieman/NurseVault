#!/bin/bash
# Xcode Run Script: Copy ClinicalCalculators into the app bundle after build.
# This script runs as part of the NurseVault target's build process.
# It copies the bundled clinical calculator HTML files into the app bundle
# at Resources/ClinicalCalculators/Data/ so the Swift code can find them.

# In a Run Script build phase, $PROJECT_DIR is the directory containing the .xcodeproj file.
# The ClinicalCalculators Data folder is at: NurseVault.xcodeproj/../Sources/iOS/Resources/ClinicalCalculators/Data

APP_BUNDLE="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"
SRC_DIR="$PROJECT_DIR/../Sources/iOS/Resources/ClinicalCalculators/Data"

if [ -d "$APP_BUNDLE" ] && [ -d "$SRC_DIR" ]; then
  RES_DIR="$APP_BUNDLE/Resources/ClinicalCalculators/Data"
  mkdir -p "$RES_DIR"
  cp "$SRC_DIR"/* "$RES_DIR/" 2>/dev/null
  COUNT=$(ls "$RES_DIR" 2>/dev/null | wc -l)
  echo "Copied $COUNT ClinicalCalculators files to bundle"
else
  echo "WARNING: Skipping ClinicalCalculators copy"
  [ ! -d "$SRC_DIR" ] && echo "  Source not found: $SRC_DIR"
  [ ! -d "$APP_BUNDLE" ] && echo "  Bundle not found: $APP_BUNDLE"
fi
