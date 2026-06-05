#!/bin/bash
# =============================================================
# generate-release-notes.sh
# Auto-generates release notes from git commits between two tags.
# Reads config from .github/release-config.yml
#
# Usage:
#   bash scripts/generate-release-notes.sh              # latest tag vs previous
#   bash scripts/generate-release-notes.sh v1.2.0       # specific tag vs previous
#   bash scripts/generate-release-notes.sh v1.2.0 v1.1.0  # between two tags
#   WRITE_FILE=true bash scripts/generate-release-notes.sh  # also save to file
# =============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---- Read config from release-config.yml ----
CONFIG_FILE=".github/release-config.yml"
PROJECT_NAME="NemiVision"
REPO="Sathishkumar/nemivision"

if [ -f "$CONFIG_FILE" ]; then
  PARSED_NAME=$(grep 'name:' "$CONFIG_FILE" | head -1 | sed 's/.*name: *"\(.*\)"/\1/')
  PARSED_REPO=$(grep 'repo:' "$CONFIG_FILE" | head -1 | sed 's/.*repo: *"\(.*\)"/\1/')
  [ -n "$PARSED_NAME" ] && PROJECT_NAME="$PARSED_NAME"
  [ -n "$PARSED_REPO" ] && REPO="$PARSED_REPO"
  echo -e "${CYAN}Config loaded from ${CONFIG_FILE}${NC}"
else
  echo -e "${YELLOW}No config file found at ${CONFIG_FILE}, using defaults${NC}"
fi

# ---- Determine tag range ----
if [ -n "$2" ]; then
  NEW_TAG="$1"
  OLD_TAG="$2"
elif [ -n "$1" ]; then
  NEW_TAG="$1"
  OLD_TAG=$(git tag --sort=-v:refname | grep -A1 "^${NEW_TAG}$" | tail -1)
else
  NEW_TAG=$(git tag --sort=-v:refname | head -1)
  OLD_TAG=$(git tag --sort=-v:refname | head -2 | tail -1)
fi

# Fallback: if only one tag exists, diff from first commit
if [ -z "$OLD_TAG" ] || [ "$OLD_TAG" = "$NEW_TAG" ]; then
  echo -e "${YELLOW}Only one tag found. Showing all commits up to ${NEW_TAG}.${NC}"
  RANGE="${NEW_TAG}"
  OLD_TAG=""
else
  RANGE="${OLD_TAG}..${NEW_TAG}"
fi

DATE=$(git log -1 --format=%ci "$NEW_TAG" 2>/dev/null | cut -d' ' -f1)
[ -z "$DATE" ] && DATE=$(date +%Y-%m-%d)

echo -e "${GREEN}${BOLD}Generating release notes for ${PROJECT_NAME} ${NEW_TAG}${NC}"
echo -e "Range: ${YELLOW}${RANGE}${NC}"
echo ""

# ---- Categorize commits ----
FEATURES=""
FIXES=""
INFRA=""
DOCS=""
OTHER=""

while IFS= read -r line; do
  [ -z "$line" ] && continue

  if echo "$line" | grep -qiE "^feat(\(.*\))?:"; then
    msg=$(echo "$line" | sed 's/^[^:]*: *//')
    FEATURES="${FEATURES}\n- ${msg}"
  elif echo "$line" | grep -qiE "^fix(\(.*\))?:"; then
    msg=$(echo "$line" | sed 's/^[^:]*: *//')
    FIXES="${FIXES}\n- ${msg}"
  elif echo "$line" | grep -qiE "^docs(\(.*\))?:"; then
    msg=$(echo "$line" | sed 's/^[^:]*: *//')
    DOCS="${DOCS}\n- ${msg}"
  elif echo "$line" | grep -qiE "^(chore|ci|build|infra|refactor)(\(.*\))?:"; then
    msg=$(echo "$line" | sed 's/^[^:]*: *//')
    INFRA="${INFRA}\n- ${msg}"
  else
    OTHER="${OTHER}\n- ${line}"
  fi
done <<< "$(git log --pretty=format:"%s" $RANGE)"

# ---- Build output ----
OUTPUT="# ${PROJECT_NAME} — Release ${NEW_TAG}\n"
OUTPUT="${OUTPUT}**Date:** ${DATE}\n\n"
OUTPUT="${OUTPUT}---\n\n"

if [ -n "$FEATURES" ]; then
  OUTPUT="${OUTPUT}## ✨ Features\n${FEATURES}\n\n"
fi

if [ -n "$FIXES" ]; then
  OUTPUT="${OUTPUT}## 🐛 Bug Fixes\n${FIXES}\n\n"
fi

if [ -n "$INFRA" ]; then
  OUTPUT="${OUTPUT}## 🔧 Infrastructure & Maintenance\n${INFRA}\n\n"
fi

if [ -n "$DOCS" ]; then
  OUTPUT="${OUTPUT}## 📚 Documentation\n${DOCS}\n\n"
fi

if [ -n "$OTHER" ]; then
  OUTPUT="${OUTPUT}## 🔬 Other Changes\n${OTHER}\n\n"
fi

# ---- Contributors ----
# Core team always listed; extra committers from git log appended
OUTPUT="${OUTPUT}## 👥 Contributors\n"
OUTPUT="${OUTPUT}\n- Mohammed Rafath <soft.develop@bncmotors.in>"
OUTPUT="${OUTPUT}\n- Mohammed Rafath M <rafath@bncmotors.in>"
GIT_CONTRIBUTORS=$(git log --pretty=format:"%aN <%aE>" $RANGE 2>/dev/null | sort -u | grep -vE "soft\.develop|rafath@bnc" || true)
while IFS= read -r c; do
  [ -n "$c" ] && OUTPUT="${OUTPUT}\n- ${c}"
done <<< "$GIT_CONTRIBUTORS"

OUTPUT="${OUTPUT}\n\n---\n"
if [ -n "$OLD_TAG" ]; then
  OUTPUT="${OUTPUT}\n**Full Changelog**: https://github.com/${REPO}/compare/${OLD_TAG}...${NEW_TAG}\n"
fi

# ---- Print ----
echo -e "$OUTPUT"

# ---- Optionally write to file ----
if [ "$WRITE_FILE" = "true" ]; then
  OUTFILE="release-notes-${NEW_TAG}.md"
  echo -e "$OUTPUT" > "$OUTFILE"
  echo -e "\n${GREEN}Saved to ${OUTFILE}${NC}"
fi
