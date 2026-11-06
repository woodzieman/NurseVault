#!/bin/bash
# Copy ClinicalCalculators folder to the app bundle
SRC="$PROJECT_DIR/Sources/iOS/Resources/ClinicalCalculators"
DST="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Resources"
if [ -d "$SRC" ]; then
  cp -R "$SRC" "$DST/"
  echo "Copied ClinicalCalculators from $SRC to $DST"
else
  echo "WARNING: ClinicalCalculators folder not found at $SRC"
fi
