#!/bin/bash

# OpenCode Release Build Script
# Usage: ./Build_Release.sh [options]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
SINGLE=false
BASELINE=false
SKIP_INSTALL=false
TARGET=""
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./Build_Release.sh [options]"
      echo ""
      echo "Options:"
      echo "  -h, --help           Show this help message"
      echo "  -s, --single         Build only for current platform"
      echo "  -b, --baseline       Build baseline version (no AVX2)"
      echo "  --skip-install       Skip installing dependencies"
      echo "  -t, --target TARGET  Build specific target (e.g., darwin-arm64, linux-x64)"
      echo "  -n, --dry-run        Show commands without executing"
      echo ""
      echo "Examples:"
      echo "  ./Build_Release.sh                    # Build all platforms"
      echo "  ./Build_Release.sh -s                 # Build current platform only"
      echo "  ./Build_Release.sh -s -b              # Build current baseline"
      echo "  ./Build_Release.sh -t darwin-arm64    # Build macOS ARM64"
      echo "  ./Build_Release.sh -t linux-x64       # Build Linux x64"
      exit 0
      ;;
    -s|--single)
      SINGLE=true
      shift
      ;;
    -b|--baseline)
      BASELINE=true
      shift
      ;;
    --skip-install)
      SKIP_INSTALL=true
      shift
      ;;
    -t|--target)
      TARGET="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/packages/opencode"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     OpenCode Release Build Script      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Get version from package.json
VERSION=$(node -e "console.log(require('./package.json').version)" 2>/dev/null || echo "unknown")
echo -e "${GREEN}Version: $VERSION${NC}"
echo ""

# Build command
BUILD_CMD="bun run script/build.ts"
if [ "$SINGLE" = true ]; then
  BUILD_CMD="$BUILD_CMD --single"
  echo -e "${YELLOW}Mode: Single platform (current)${NC}"
else
  echo -e "${YELLOW}Mode: All platforms${NC}"
fi

if [ "$BASELINE" = true ]; then
  BUILD_CMD="$BUILD_CMD --baseline"
  echo -e "${YELLOW}Baseline: enabled${NC}"
fi

if [ "$SKIP_INSTALL" = true ]; then
  BUILD_CMD="$BUILD_CMD --skip-install"
  echo -e "${YELLOW}Skip install: enabled${NC}"
fi

if [ -n "$TARGET" ]; then
  # Extract platform and arch from target (e.g., darwin-arm64 -> darwin arm64)
  PLATFORM=$(echo "$TARGET" | cut -d'-' -f1)
  ARCH=$(echo "$TARGET" | cut -d'-' -f2)
  echo -e "${YELLOW}Target: $PLATFORM-$ARCH${NC}"

  # Map platform names
  case $PLATFORM in
    macos|darwin) PLATFORM="darwin" ;;
    linux) PLATFORM="linux" ;;
    windows|win32) PLATFORM="win32" ;;
  esac
fi

echo ""

# Confirm build
if [ "$DRY_RUN" = false ]; then
  read -p "$(echo -e ${GREEN}Continue? [Y/n]: ${NC})" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo -e "${RED}Build cancelled${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}────────────────────────────────────────────${NC}"
echo ""

# Execute build
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Would execute: $BUILD_CMD${NC}"
else
  START_TIME=$(date +%s)

  # Run build
  eval $BUILD_CMD

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  echo ""
  echo -e "${GREEN}✓ Build completed in ${DURATION}s${NC}"
  echo ""

  # Show output
  if [ -d "dist" ]; then
    echo -e "${BLUE}Built binaries:${NC}"
    for dir in dist/*/bin; do
      if [ -d "$dir" ]; then
        NAME=$(basename $(dirname "$dir"))
        SIZE=$(du -sh "$dir" | cut -f1)
        echo -e "  ${GREEN}•${NC} $NAME ($SIZE)"
      fi
    done
    echo ""
  fi

  # Check for release archives
  if ls ./*.tar.gz ./*.zip 2>/dev/null | grep -q .; then
    echo -e "${BLUE}Release archives:${NC}"
    for archive in *.tar.gz *.zip; do
      if [ -f "$archive" ]; then
        SIZE=$(du -h "$archive" | cut -f1)
        echo -e "  ${GREEN}•${NC} $archive ($SIZE)"
      fi
    done
    echo ""
  fi

  echo -e "${GREEN}Done!${NC}"
fi
