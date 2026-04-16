#!/bin/bash
# Run this once after cloning and filling in config.yml

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
header()  { echo -e "\n${BOLD}$1${RESET}"; }

# -----------------------------------------------
# Helpers
# -----------------------------------------------

parse() {
  grep "^$1:" "$CONFIG" | sed "s/^$1:[[:space:]]*//"
}

sedi() {
  if [ "$(uname)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# -----------------------------------------------
# Check config exists
# -----------------------------------------------

header "resume-forge setup"

if [ ! -f "$CONFIG" ]; then
  error "config.yml not found"
  echo "      Copy the example and fill it in:"
  echo "        cp config.example.yml config.yml"
  exit 1
fi

success "Found config.yml"

# -----------------------------------------------
# Read & validate config
# -----------------------------------------------

header "Reading config..."

USER_NAME=$(parse user_name)
SHELL_CONFIG=$(parse shell_config | sed "s|~|$HOME|g")

if [ "$USER_NAME" = "your_name" ] || [ -z "$USER_NAME" ]; then
  error "user_name is not set in config.yml"
  echo "      Open config.yml and replace 'your_name' with your actual name (e.g. john_doe)"
  exit 1
fi

success "user_name: $USER_NAME"

if [ -z "$SHELL_CONFIG" ]; then
  warning "shell_config not set — defaulting to ~/.zshrc"
  SHELL_CONFIG="$HOME/.zshrc"
fi

if [ ! -f "$SHELL_CONFIG" ]; then
  warning "Shell config not found: $SHELL_CONFIG"
  echo "      Creating it..."
  touch "$SHELL_CONFIG"
fi

success "shell_config: $SHELL_CONFIG"

# -----------------------------------------------
# Detect OS
# -----------------------------------------------

header "Detecting environment..."

OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
  success "OS: macOS"
elif [ "$OS" = "Linux" ]; then
  success "OS: Linux"
else
  warning "OS: $OS — this kit is tested on Mac and Linux. Proceed with caution."
fi

# -----------------------------------------------
# Auto-detect pdflatex
# -----------------------------------------------

info "Looking for pdflatex..."

find_pdflatex() {
  if command -v pdflatex &>/dev/null; then
    command -v pdflatex
    return
  fi

  if [ "$OS" = "Darwin" ]; then
    CANDIDATES=(
      "$HOME/Library/TinyTeX/bin/universal-darwin/pdflatex"
      "$HOME/.TinyTeX/bin/universal-darwin/pdflatex"
      "$HOME/.TinyTeX/bin/x86_64-darwin/pdflatex"
      "/usr/local/bin/pdflatex"
    )
  else
    CANDIDATES=(
      "$HOME/.TinyTeX/bin/x86_64-linux/pdflatex"
      "$HOME/.TinyTeX/bin/aarch64-linux/pdflatex"
      "/usr/bin/pdflatex"
      "/usr/local/bin/pdflatex"
    )
  fi

  for path in "${CANDIDATES[@]}"; do
    if [ -f "$path" ]; then
      echo "$path"
      return
    fi
  done

  echo ""
}

PDFLATEX_PATH=$(find_pdflatex)

if [ -z "$PDFLATEX_PATH" ]; then
  error "pdflatex not found"
  echo "      Install TinyTeX and required packages:"
  echo ""
  echo "        curl -sL https://yihui.org/tinytex/install-bin-unix.sh | sh"
  echo "        tlmgr install preprint marvosym enumitem titlesec fancyhdr collection-latexrecommended"
  echo ""
  exit 1
fi

success "Found pdflatex: $PDFLATEX_PATH"

# -----------------------------------------------
# Auto-detect VS Code
# -----------------------------------------------

info "Looking for VS Code..."

find_vscode() {
  if command -v code &>/dev/null; then
    command -v code
    return
  fi

  if [ "$OS" = "Darwin" ]; then
    CANDIDATES=(
      "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
      "/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
    )
  else
    CANDIDATES=(
      "/usr/bin/code"
      "/usr/local/bin/code"
      "/snap/bin/code"
    )
  fi

  for path in "${CANDIDATES[@]}"; do
    if [ -f "$path" ]; then
      echo "$path"
      return
    fi
  done

  echo ""
}

VSCODE_PATH=$(find_vscode)

if [ -z "$VSCODE_PATH" ]; then
  warning "VS Code not found — files will not auto-open after forge"
  echo "      Install VS Code from https://code.visualstudio.com"
  VSCODE_PATH="code"
else
  success "Found VS Code: $VSCODE_PATH"
fi

# -----------------------------------------------
# Update .vscode/settings.json
# -----------------------------------------------

header "Configuring VS Code..."

SETTINGS="$SCRIPT_DIR/.vscode/settings.json"

if [ ! -f "$SETTINGS" ]; then
  error ".vscode/settings.json not found at: $SETTINGS"
  exit 1
fi

sedi "s|\"command\":.*pdflatex.*|\"command\": \"$PDFLATEX_PATH\",|" "$SETTINGS"
success "Updated .vscode/settings.json"

# -----------------------------------------------
# Save detected paths to config.yml
# -----------------------------------------------

if ! grep -q "^pdflatex_path:" "$CONFIG"; then
  echo "pdflatex_path: $PDFLATEX_PATH" >> "$CONFIG"
fi

if ! grep -q "^vscode_path:" "$CONFIG"; then
  echo "vscode_path: $VSCODE_PATH" >> "$CONFIG"
fi

success "Saved paths to config.yml"

# -----------------------------------------------
# Add forge alias to shell config
# -----------------------------------------------

header "Setting up shell alias..."

ALIAS_MARKER="# resume-forge"
if grep -q "$ALIAS_MARKER" "$SHELL_CONFIG" 2>/dev/null; then
  warning "Shell alias already exists in $SHELL_CONFIG — skipping"
else
  echo "" >> "$SHELL_CONFIG"
  echo "$ALIAS_MARKER" >> "$SHELL_CONFIG"
  echo "forge() { \"$SCRIPT_DIR/forge.sh\" \"\$1\" \"\$2\"; }" >> "$SHELL_CONFIG"
  success "Added forge alias to $SHELL_CONFIG"
fi

# -----------------------------------------------
# Done
# -----------------------------------------------

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${RESET}"
echo ""
echo "  Reload your shell:"
echo -e "    ${BOLD}source $SHELL_CONFIG${RESET}"
echo ""
echo "  Then create your first CV:"
echo -e "    ${BOLD}forge \"Company Name\" resume${RESET}"
echo ""
