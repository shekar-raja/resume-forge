#!/bin/bash

SCRIPT_DIR="${TEX_AND_GO_HOME:-$(cd "$(dirname "$0")" && pwd)}"
CONFIG="$SCRIPT_DIR/config.yml"

# -----------------------------------------------
# Colors & formatting
# -----------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

error()   { echo -e "${RED}✗ $1${RESET}"; }
success() { echo -e "${GREEN}✓ $1${RESET}"; }
warning() { echo -e "${YELLOW}⚠ $1${RESET}"; }
info()    { echo -e "${BLUE}→ $1${RESET}"; }

# -----------------------------------------------
# Check config exists
# -----------------------------------------------

if [ ! -f "$CONFIG" ]; then
  error "config.yml not found — have you run ./setup.sh yet?"
  exit 1
fi

# -----------------------------------------------
# Read config
# -----------------------------------------------

parse() {
  grep "^$1:" "$CONFIG" | sed "s/^$1:[[:space:]]*//"
}

USER_NAME=$(parse user_name)
VSCODE_PATH=$(parse vscode_path)

if [ "$USER_NAME" = "your_name" ] || [ -z "$USER_NAME" ]; then
  error "user_name is not set in config.yml"
  echo "      Open config.yml and set your name"
  exit 1
fi

if [ -z "$VSCODE_PATH" ]; then
  warning "vscode_path not found in config — run ./setup.sh to fix this"
  VSCODE_PATH="code"
fi

# -----------------------------------------------
# Check masters exist
# -----------------------------------------------

MASTERS_DIR="$SCRIPT_DIR/masters"
MASTERS=("$MASTERS_DIR"/*.tex)

if [ ! -e "${MASTERS[0]}" ]; then
  error "No master CVs found in masters/"
  echo "      Add a .tex file to the masters/ folder to get started"
  exit 1
fi

# -----------------------------------------------
# Banner — adaptive width, dashed borders, Claude-style
# -----------------------------------------------

# Detect terminal width, clamp between 60 and 100
TW=$(tput cols 2>/dev/null || echo 80)
[ "$TW" -lt 60 ] && TW=60
[ "$TW" -gt 100 ] && TW=100

# Left panel = 38% of width, right panel fills the rest (for bottom section)
L=$(( TW * 38 / 100 ))
R=$(( TW - L - 3 ))   # 3 = left border + separator + right border
IW=$(( TW - 2 ))      # inner width (full-width rows)

# Collect master names
MASTER_NAMES=()
for f in "${MASTERS[@]}"; do
  MASTER_NAMES+=("$(basename "$f" .tex)")
done

padl() { printf "%-${L}s" "$1"; }

# Full-width row (top section — no column split, right border included)
rowfw() {
  printf "${YELLOW}│${RESET}%-${IW}s${YELLOW}│${RESET}\n" "$1"
}

# Two-column row with right border — right content must be plain ASCII
row() {
  printf "${YELLOW}│${RESET}$(padl "$1")${YELLOW}│${RESET} %-$((R-1))s${YELLOW}│${RESET}\n" "$2"
}

# Two-column row with green right header and right border — right content plain ASCII
rowh() {
  local rpad
  rpad=$(printf "%-$((R-1))s" "$2")
  printf "${YELLOW}│${RESET}$(padl "$1")${YELLOW}│${RESET} ${GREEN}${rpad}${RESET}${YELLOW}│${RESET}\n"
}

# Two-column separator row: right column filled with ─ (bypasses UTF-8 padding)
rowsep() {
  printf "${YELLOW}│${RESET}$(padl "$1")${YELLOW}│${RESET}$(printf '─%.0s' $(seq 1 $R))${YELLOW}│${RESET}\n"
}

# Full-width horizontal rule
hrule_fw() {
  local lc="${1:-├}" rc="${2:-┤}"
  printf "${YELLOW}${lc}"; printf '─%.0s' $(seq 1 $((TW-2))); printf "${rc}${RESET}\n"
}

# Two-column horizontal rule (with junction character)
hrule_2col() {
  local lc="${1:-├}" mc="${2:-┬}" rc="${3:-┤}"
  printf "${YELLOW}${lc}"; printf '─%.0s' $(seq 1 $L); printf "${mc}"; printf '─%.0s' $(seq 1 $R); printf "${rc}${RESET}\n"
}

TITLE_VIS=18            # visual length of "resume-forge v1.0.0"
DASHES=$(( TW - TITLE_VIS - 8 ))

echo ""
# Top border with title embedded
echo -e "${YELLOW}╭$(printf '─%.0s' {1..3}) ${GREEN}${BOLD}resume-forge${RESET}${YELLOW} v1.0.0 $(printf '─%.0s' $(seq 1 $DASHES))╮${RESET}"

# Top section — full width, no column split
rowfw "  Welcome back, ${USER_NAME}!"
rowfw ""
rowfw "   .---------.   .---------.   Write. Preview. Submit."
rowfw "   |  .tex   |-->|  .pdf   |   No Overleaf needed."
rowfw "   |  ~~~~~  |   |  ~~~~~  |"
rowfw "   '---------'   '---------'"
rowfw ""

# Mid separator with column junction (┬ connects to the column split below)
hrule_2col "├" "┬" "┤"

# Bottom section — two-column with right border
rowh "  user: ${USER_NAME}"   "Quick start"
rowsep ""
row  ""  "  1. forge  - create a new company CV"
row  ""  "  2. Edit the .tex file in VS Code"
row  ""  "  3. Save   - PDF compiles automatically"
row  ""  "  4. Submit the PDF to your application"
row  ""  ""
rowh ""  "Available masters"
rowsep ""

MAX=5
COUNT=0
for name in "${MASTER_NAMES[@]}"; do
  if [ $COUNT -lt $MAX ]; then
    DISPLAY="  ${name}"
    [ ${#DISPLAY} -gt $((R-2)) ] && DISPLAY="${DISPLAY:0:$((R-5))}..."
    row "" "$DISPLAY"
    COUNT=$((COUNT + 1))
  fi
done
[ ${#MASTER_NAMES[@]} -gt $MAX ] && row "" "  ... and $((${#MASTER_NAMES[@]} - MAX)) more"
row "" ""

# Bottom border
echo -e "${YELLOW}╰$(printf '─%.0s' $(seq 1 $((TW-2))))╯${RESET}"
echo ""

# Preview-only mode: print banner and exit (used for screenshot generation)
[ "$1" = "--preview" ] && exit 0

while true; do
  echo -e "${BLUE}Company name:${RESET} \c"
  read -r COMPANY

  if [ -z "$COMPANY" ]; then
    warning "Company name cannot be empty. Please try again."
  else
    break
  fi
done

# -----------------------------------------------
# Ask: Choose master CV
# -----------------------------------------------

echo ""
echo -e "${BLUE}Choose a master CV:${RESET}"
echo ""

INDEX=1
for f in "${MASTERS[@]}"; do
  echo "  [$INDEX] $(basename "$f" .tex)"
  INDEX=$((INDEX + 1))
done

echo ""

MASTER_COUNT=${#MASTERS[@]}

while true; do
  echo -e "${BLUE}Enter number (1-${MASTER_COUNT}):${RESET} \c"
  read -r CHOICE

  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$MASTER_COUNT" ]; then
    MASTER="${MASTERS[$((CHOICE - 1))]}"
    MASTER_NAME="$(basename "$MASTER" .tex)"
    break
  else
    warning "Invalid choice. Please enter a number between 1 and ${MASTER_COUNT}."
  fi
done

# -----------------------------------------------
# Create company folder and copy master
# -----------------------------------------------

echo ""

DEST_DIR="$SCRIPT_DIR/companies/$COMPANY"
DEST_FILE="$DEST_DIR/${USER_NAME}_cv.tex"

mkdir -p "$DEST_DIR"

if [ -f "$DEST_FILE" ]; then
  warning "CV already exists for $COMPANY — opening existing file"
else
  cp "$MASTER" "$DEST_FILE"
  success "Created: companies/$COMPANY/${USER_NAME}_cv.tex  (from $MASTER_NAME)"
fi

# -----------------------------------------------
# Open in VS Code
# -----------------------------------------------

info "Opening in VS Code..."

if ! "$VSCODE_PATH" "$DEST_FILE" 2>/dev/null; then
  warning "Could not open VS Code automatically"
  echo "      Open this file manually:"
  echo "        $DEST_FILE"
  exit 1
fi

echo ""
success "Done!"
echo ""
echo -e "${BOLD}  Your files:${RESET}"
echo "    TEX  →  $DEST_FILE"
echo "    PDF  →  $DEST_DIR/${USER_NAME}_cv.pdf  (generated on first save)"
echo ""
echo -e "${BOLD}  Next steps:${RESET}"
echo "    1. Edit your CV in VS Code"
echo "    2. Hit Cmd+S (Mac) / Ctrl+S (Linux) to compile"
echo "    3. Click 'View LaTeX PDF' to preview side by side"
echo "    4. Submit the PDF from the path above"
echo ""
