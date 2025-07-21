#!/bin/bash

# embedJS.sh - Extract JS from TypeScript wrapper and embed as base64 in Swift

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for QuickJS
if ! command -v qjs &> /dev/null; then
    echo -e "${RED}Error: qjs (QuickJS) not found${NC}"
    echo -e "${YELLOW}Install it with: brew install quickjs${NC}"
    exit 1
fi

# Check for GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh (GitHub CLI) not found${NC}"
    echo -e "${YELLOW}Install it with: brew install gh${NC}"
    echo -e "${YELLOW}Then authenticate with: gh auth login${NC}"
    exit 1
fi

# Configuration
REPO="segment-integrations/signals-specs"
FILE_PATH="packages/signals-runtime/src/mobile/get-runtime-code.generated.ts"
OUTPUT_FILE="Sources/AnalyticsLive/Signals/Runtime/SignalsJS.swift"
TEMP_FILE=$(mktemp)

echo -e "${YELLOW}Fetching latest release info...${NC}"

# Get the latest release tag using GitHub CLI
LATEST_TAG=$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName')

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
    echo -e "${RED}Error: Could not fetch latest release tag${NC}"
    echo -e "${YELLOW}Make sure you're authenticated with: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}Latest release: $LATEST_TAG${NC}"
# Extract just the version number (everything after the last @)
VERSION_NUMBER=$(echo "$LATEST_TAG" | sed 's/.*@//')
echo -e "${GREEN}Version number: $VERSION_NUMBER${NC}"
echo -e "${YELLOW}Downloading JS from GitHub API...${NC}"

# Use GitHub API to get file content from the specific tag (properly escaped)
if ! gh api "repos/$REPO/contents/$FILE_PATH?ref=$LATEST_TAG" --jq '.content' | base64 -d > "$TEMP_FILE"; then
    echo -e "${RED}Error: Failed to download from $REPO/$FILE_PATH at tag $LATEST_TAG${NC}"
    echo -e "${YELLOW}Make sure you're authenticated with: gh auth login${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

GITHUB_REPO_URL="https://github.com/$REPO/blob/$LATEST_TAG/$FILE_PATH"

echo -e "${YELLOW}Extracting JavaScript content...${NC}"

# Extract JS between backticks using awk
JS_CONTENT=$(awk '/export const getRuntimeCode.*`$/{flag=1; next} /^`$/{flag=0} flag' "$TEMP_FILE")

# Check if we actually extracted something
if [ -z "$JS_CONTENT" ]; then
    echo -e "${RED}Error: No JavaScript content found between backticks${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo -e "${YELLOW}Validating JavaScript with QuickJS...${NC}"

# Write JS to temp file for validation
JS_TEMP_FILE=$(mktemp -t "extracted_js.XXXXXX.js")
echo "$JS_CONTENT" > "$JS_TEMP_FILE"

# Validate JS with QuickJS
if ! qjs "$JS_TEMP_FILE" &> /dev/null; then
    echo -e "${RED}Error: JavaScript validation failed!${NC}"
    echo -e "${RED}The extracted JS appears to be invalid or incomplete${NC}"
    rm -f "$TEMP_FILE" "$JS_TEMP_FILE"
    exit 1
fi

# Cleanup JS temp file
rm -f "$JS_TEMP_FILE"

echo -e "${GREEN}✅ JavaScript validation passed${NC}"

echo -e "${YELLOW}Base64 encoding and chunking JavaScript...${NC}"

# Base64 encode it
BASE64_JS=$(echo -n "$JS_CONTENT" | base64)

# Split base64 into chunks for IDE readability
echo "// GENERATED - DO NOT EDIT" > "$OUTPUT_FILE"
echo "// Source: $GITHUB_REPO_URL" >> "$OUTPUT_FILE"
echo "// Release: $LATEST_TAG" >> "$OUTPUT_FILE"
echo "// Generated: $(date)" >> "$OUTPUT_FILE"
echo "//" >> "$OUTPUT_FILE"
echo "// This JavaScript is stored as chunked base64 because:" >> "$OUTPUT_FILE"
echo "// 1. The original JS is minified into one very long line" >> "$OUTPUT_FILE"
echo "// 2. Xcode won't display extremely long strings in the editor" >> "$OUTPUT_FILE"
echo "// 3. Breaking the base64 into 80-character chunks makes it visible" >> "$OUTPUT_FILE"
echo "//" >> "$OUTPUT_FILE"
echo "// At runtime, the chunks are joined, decoded, and the JavaScript is ready to use." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "import Foundation" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "internal class SignalsRuntime {" >> "$OUTPUT_FILE"
echo "    static let version: String = \"$VERSION_NUMBER\"" >> "$OUTPUT_FILE"
echo "    static let embeddedJS: String = {" >> "$OUTPUT_FILE"
echo "        let encodedChunks = [" >> "$OUTPUT_FILE"

# Split base64 into 80-character chunks
echo "$BASE64_JS" | fold -w 80 | sed 's/.*/"&",/' >> "$OUTPUT_FILE"

echo "        ]" >> "$OUTPUT_FILE"
echo "        let encoded = encodedChunks.joined()" >> "$OUTPUT_FILE"
echo "        guard let data = Data(base64Encoded: encoded)," >> "$OUTPUT_FILE"
echo "              let decoded = String(data: data, encoding: .utf8) else {" >> "$OUTPUT_FILE"
echo "            fatalError(\"Failed to decode runtime JS\")" >> "$OUTPUT_FILE"
echo "        }" >> "$OUTPUT_FILE"
echo "        return decoded" >> "$OUTPUT_FILE"
echo "    }()" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

# Cleanup
rm -f "$TEMP_FILE"

echo -e "${GREEN}✅ Successfully generated $OUTPUT_FILE${NC}"
echo -e "${GREEN}📊 JS size: $(echo -n "$JS_CONTENT" | wc -c) bytes${NC}"
echo -e "${GREEN}📊 Base64 size: $(echo -n "$BASE64_JS" | wc -c) bytes${NC}"
