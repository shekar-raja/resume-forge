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
RESUME_MASTERS_DIR="$MASTERS_DIR/resume"
COVER_LETTER_MASTERS_DIR="$MASTERS_DIR/cover_letter"

RESUME_MASTERS=("$RESUME_MASTERS_DIR"/*.tex)
COVER_LETTER_MASTERS=("$COVER_LETTER_MASTERS_DIR"/*.tex)

if [ ! -e "${RESUME_MASTERS[0]}" ] && [ ! -e "${COVER_LETTER_MASTERS[0]}" ]; then
  error "No master templates found in masters/resume/ or masters/cover_letter/"
  echo "      Add .tex files to the masters/resume/ and/or masters/cover_letter/ folders"
  exit 1
fi

# -----------------------------------------------
# Banner — adaptive width, dashed borders, Claude-style
# -----------------------------------------------

# Detect terminal width, clamp between 60 and 100
TW=$(tput cols 2>/dev/null || echo 80)
[ "$TW" -lt 60 ] && TW=60
[ "$TW" -gt 100 ] && TW=100

# Left panel = 28% of width, right panel fills the rest (for bottom section)
L=$(( TW * 28 / 100 ))
R=$(( TW - L - 3 ))   # 3 = left border + separator + right border
IW=$(( TW - 2 ))      # inner width (full-width rows)

# Collect master names for both categories
RESUME_MASTER_NAMES=()
if [ -e "${RESUME_MASTERS[0]}" ]; then
  for f in "${RESUME_MASTERS[@]}"; do
    RESUME_MASTER_NAMES+=("$(basename "$f" .tex)")
  done
fi

COVER_LETTER_MASTER_NAMES=()
if [ -e "${COVER_LETTER_MASTERS[0]}" ]; then
  for f in "${COVER_LETTER_MASTERS[@]}"; do
    COVER_LETTER_MASTER_NAMES+=("$(basename "$f" .tex)")
  done
fi

padl() { printf "%-${L}s" "$1"; }

# Full-width row (top section — no column split, right border included)
rowfw() {
  printf "${YELLOW}│${RESET}%-${IW}s${YELLOW}│${RESET}\n" "$1"
}

# Two-column row with right border — right content must be plain ASCII
row() {
  local content="$2"
  local maxlen=$((R-1))
  [ ${#content} -gt $maxlen ] && content="${content:0:$((maxlen-3))}..."
  printf "${YELLOW}│${RESET}$(padl "$1")${YELLOW}│${RESET} %-$((R-1))s${YELLOW}│${RESET}\n" "$content"
}

# Two-column row with green right header and right border — right content plain ASCII
rowh() {
  local content="$2"
  local maxlen=$((R-1))
  [ ${#content} -gt $maxlen ] && content="${content:0:$((maxlen-3))}..."
  local rpad
  rpad=$(printf "%-$((R-1))s" "$content")
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
row  ""  "  1. forge  - create CV, cover letter, or both"
row  ""  "  2. Edit the .tex file in VS Code"
row  ""  "  3. Save   - PDF compiles automatically"
row  ""  "  4. Submit the PDF to your application"
row  ""  ""

# Show resume masters
if [ ${#RESUME_MASTER_NAMES[@]} -gt 0 ]; then
  rowh ""  "Resume masters"
  rowsep ""
  MAX=3
  COUNT=0
  for name in "${RESUME_MASTER_NAMES[@]}"; do
    if [ $COUNT -lt $MAX ]; then
      DISPLAY="  ${name}"
      [ ${#DISPLAY} -gt $((R-2)) ] && DISPLAY="${DISPLAY:0:$((R-5))}..."
      row "" "$DISPLAY"
      COUNT=$((COUNT + 1))
    fi
  done
  [ ${#RESUME_MASTER_NAMES[@]} -gt $MAX ] && row "" "  ... and $((${#RESUME_MASTER_NAMES[@]} - MAX)) more"
  row "" ""
fi

# Show cover letter masters
if [ ${#COVER_LETTER_MASTER_NAMES[@]} -gt 0 ]; then
  rowh ""  "Cover letter masters"
  rowsep ""
  MAX=3
  COUNT=0
  for name in "${COVER_LETTER_MASTER_NAMES[@]}"; do
    if [ $COUNT -lt $MAX ]; then
      DISPLAY="  ${name}"
      [ ${#DISPLAY} -gt $((R-2)) ] && DISPLAY="${DISPLAY:0:$((R-5))}..."
      row "" "$DISPLAY"
      COUNT=$((COUNT + 1))
    fi
  done
  [ ${#COVER_LETTER_MASTER_NAMES[@]} -gt $MAX ] && row "" "  ... and $((${#COVER_LETTER_MASTER_NAMES[@]} - MAX)) more"
  row "" ""
fi

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
# Ask: Role name (optional, for multiple roles at same company)
# -----------------------------------------------

# Helper: normalize role name to lowercase with underscores
normalize_role() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g'
}

echo -e "${BLUE}Role name (optional, press Enter to skip):${RESET} \c"
read -r ROLE_INPUT

ROLE=""
if [ -n "$ROLE_INPUT" ]; then
  ROLE=$(normalize_role "$ROLE_INPUT")
  info "Role normalized to: $ROLE"
fi

# -----------------------------------------------
# Ask: What to create (CV, Cover Letter, or Both)
# -----------------------------------------------

echo ""
echo -e "${BLUE}What would you like to create?${RESET}"
echo ""
echo "  [1] Resume/CV"
echo "  [2] Cover letter"
echo "  [3] Both"
echo ""

while true; do
  echo -e "${BLUE}Enter choice (1-3):${RESET} \c"
  read -r DOC_CHOICE

  case "$DOC_CHOICE" in
    1) DOC_TYPE="cv"; break ;;
    2) DOC_TYPE="cover"; break ;;
    3) DOC_TYPE="both"; break ;;
    *) warning "Invalid choice. Please enter 1, 2, or 3." ;;
  esac
done

# -----------------------------------------------
# Helper function: Select a master template
# -----------------------------------------------

select_master() {
  local masters_array=("$@")
  local master_count=${#masters_array[@]}
  local selected_master=""

  echo "" >&2
  INDEX=1
  for f in "${masters_array[@]}"; do
    echo "  [$INDEX] $(basename "$f" .tex)" >&2
    INDEX=$((INDEX + 1))
  done
  echo "" >&2

  while true; do
    echo -e "${BLUE}Enter number (1-${master_count}):${RESET} \c" >&2
    read -r CHOICE

    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$master_count" ]; then
      selected_master="${masters_array[$((CHOICE - 1))]}"
      break
    else
      warning "Invalid choice. Please enter a number between 1 and ${master_count}." >&2
    fi
  done

  echo "$selected_master"
}

# -----------------------------------------------
# Select master(s) based on document type
# -----------------------------------------------

RESUME_MASTER=""
COVER_LETTER_MASTER=""

if [ "$DOC_TYPE" = "cv" ] || [ "$DOC_TYPE" = "both" ]; then
  if [ ! -e "${RESUME_MASTERS[0]}" ]; then
    error "No resume masters found in masters/resume/"
    exit 1
  fi
  echo ""
  echo -e "${BLUE}Choose a resume master:${RESET}"
  RESUME_MASTER=$(select_master "${RESUME_MASTERS[@]}")
  RESUME_MASTER_NAME="$(basename "$RESUME_MASTER" .tex)"
fi

if [ "$DOC_TYPE" = "cover" ] || [ "$DOC_TYPE" = "both" ]; then
  if [ ! -e "${COVER_LETTER_MASTERS[0]}" ]; then
    error "No cover letter masters found in masters/cover_letter/"
    exit 1
  fi
  echo ""
  echo -e "${BLUE}Choose a cover letter master:${RESET}"
  COVER_LETTER_MASTER=$(select_master "${COVER_LETTER_MASTERS[@]}")
  COVER_LETTER_MASTER_NAME="$(basename "$COVER_LETTER_MASTER" .tex)"
fi

# -----------------------------------------------
# Create company folder(s) and copy master(s)
# -----------------------------------------------

echo ""

# Build company directory path (with optional role subfolder)
if [ -n "$ROLE" ]; then
  COMPANY_DIR="$SCRIPT_DIR/companies/$COMPANY/$ROLE"
  DISPLAY_PATH="companies/$COMPANY/$ROLE"
else
  COMPANY_DIR="$SCRIPT_DIR/companies/$COMPANY"
  DISPLAY_PATH="companies/$COMPANY"
fi

RESUME_DEST_DIR="$COMPANY_DIR/resume"
COVER_LETTER_DEST_DIR="$COMPANY_DIR/cover_letter"

FILES_TO_OPEN=()

# Create resume if requested
if [ -n "$RESUME_MASTER" ]; then
  mkdir -p "$RESUME_DEST_DIR"
  RESUME_DEST_FILE="$RESUME_DEST_DIR/${USER_NAME}_cv.tex"

  if [ -f "$RESUME_DEST_FILE" ]; then
    warning "Resume already exists for $DISPLAY_PATH — will open existing file"
  else
    cp "$RESUME_MASTER" "$RESUME_DEST_FILE"
    success "Created: $DISPLAY_PATH/resume/${USER_NAME}_cv.tex  (from $RESUME_MASTER_NAME)"
  fi
  FILES_TO_OPEN+=("$RESUME_DEST_FILE")
fi

# Create cover letter if requested
if [ -n "$COVER_LETTER_MASTER" ]; then
  mkdir -p "$COVER_LETTER_DEST_DIR"
  COVER_LETTER_DEST_FILE="$COVER_LETTER_DEST_DIR/${USER_NAME}_cover_letter.tex"

  if [ -f "$COVER_LETTER_DEST_FILE" ]; then
    warning "Cover letter already exists for $DISPLAY_PATH — will open existing file"
  else
    cp "$COVER_LETTER_MASTER" "$COVER_LETTER_DEST_FILE"
    success "Created: $DISPLAY_PATH/cover_letter/${USER_NAME}_cover_letter.tex  (from $COVER_LETTER_MASTER_NAME)"
  fi
  FILES_TO_OPEN+=("$COVER_LETTER_DEST_FILE")
fi

# -----------------------------------------------
# Open in VS Code
# -----------------------------------------------

info "Opening in VS Code..."

for file in "${FILES_TO_OPEN[@]}"; do
  if ! "$VSCODE_PATH" "$file" 2>/dev/null; then
    warning "Could not open VS Code automatically"
    echo "      Open this file manually:"
    echo "        $file"
  fi
done

echo ""
success "Done!"
echo ""
echo -e "${BOLD}  Your files:${RESET}"

if [ -n "$RESUME_MASTER" ]; then
  echo "    Resume TEX  →  $RESUME_DEST_FILE"
  echo "    Resume PDF  →  $RESUME_DEST_DIR/${USER_NAME}_cv.pdf  (generated on first save)"
fi

if [ -n "$COVER_LETTER_MASTER" ]; then
  echo "    Cover TEX   →  $COVER_LETTER_DEST_FILE"
  echo "    Cover PDF   →  $COVER_LETTER_DEST_DIR/${USER_NAME}_cover_letter.pdf  (generated on first save)"
fi

echo ""
echo -e "${BOLD}  Next steps:${RESET}"
echo "    1. Edit your document(s) in VS Code"
echo "    2. Hit Cmd+S (Mac) / Ctrl+S (Linux) to compile"
echo "    3. Click 'View LaTeX PDF' to preview side by side"
echo "    4. Submit the PDF(s) to your application"
echo ""
