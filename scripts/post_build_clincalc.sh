#!/bin/bash
# Post-build script: copy ClinicalCalculators folder into the app bundle
APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"
SRC_DIR="Sources/iOS/Resources/ClinicalCalculators"

if [ -d "$SRC_DIR" ] && [ -d "$APP" ]; then
  RESOURCES_DIR="$APP/Resources"
  mkdir -p "$RESOURCES_DIR"
  cp -R "$SRC_DIR"/* "$RESOURCES_DIR/" 2>/dev/null
  echo "Post-build: ClinicalCalculators copied to $RESOURCES_DIR"
  ls "$RESOURCES_DIR" | head -5
  echo "... ($(ls "$RESOURCES_DIR" | wc -l) items total)"
else
  echo "SKIP: APP=$APP SRC=$SRC_DIR"
  echo "  APP exists: $([ -d "$APP" ] && echo YES || echo NO)"
  echo "  SRC exists: $([ -d "$SRC_DIR" ] && echo YES || echo NO)"
fi
