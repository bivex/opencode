#!/bin/bash

# Quick build for current platform
# Usage: ./Build.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Building OpenCode for current platform...${NC}"

cd "$(dirname "${BASH_SOURCE[0]}")/packages/opencode"

# Build single binary for current platform
bun run script/build.ts --single

echo ""
echo -e "${GREEN}✓ Build complete!${NC}"

# Show output
if [ -d "dist" ]; then
  echo ""
  echo -e "${BLUE}Built binary:${NC}"
  for dir in dist/*/bin; do
    if [ -d "$dir" ]; then
      NAME=$(basename $(dirname "$dir"))
      BIN="$dir/opencode"
      if [ -f "$BIN" ]; then
        SIZE=$(du -h "$BIN" | cut -f1)
        echo -e "  ${GREEN}•${NC} dist/${NAME}/bin/opencode ($SIZE)"
      fi
    fi
  done
fi
