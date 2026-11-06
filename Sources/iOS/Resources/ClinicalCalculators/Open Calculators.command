#!/bin/bash
# Double-click me (in Finder) to open the Merck Manual clinical calculator catalog.
DIR="$(cd "$(dirname "$0")" && pwd)"
open -a Safari "$DIR/index.html" 2>/dev/null || open "$DIR/index.html"
