#!/usr/bin/env bash
set -euo pipefail

# projectask installer
# Creates symlinks in ~/.claude for commands and skills

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

usage() {
  echo "Usage: $0 [install|uninstall]"
  echo ""
  echo "  install    Create symlinks (default)"
  echo "  uninstall  Remove symlinks"
}

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo -e "${YELLOW}skip${NC} $dest (exists, not a symlink)"
    return
  fi
  ln -s "$src" "$dest"
  echo -e "${GREEN}link${NC} $dest -> $src"
}

unlink() {
  local dest="$1"
  if [ -L "$dest" ]; then
    rm "$dest"
    echo -e "${GREEN}removed${NC} $dest"
  elif [ -e "$dest" ]; then
    echo -e "${YELLOW}skip${NC} $dest (not a symlink, leaving alone)"
  else
    echo -e "${YELLOW}skip${NC} $dest (not found)"
  fi
}

install() {
  echo "Installing projectask..."
  echo ""

  mkdir -p "$COMMANDS_DIR" "$SKILLS_DIR"

  for cmd in projectask projectask-list projectask-start projectask-done; do
    link "$REPO_DIR/commands/$cmd.md" "$COMMANDS_DIR/$cmd.md"
  done

  link "$REPO_DIR/skills/projectask" "$SKILLS_DIR/projectask"

  echo ""
  echo -e "${GREEN}Done!${NC} 4 commands + 1 skill installed."
}

uninstall() {
  echo "Uninstalling projectask..."
  echo ""

  for cmd in projectask projectask-list projectask-start projectask-done; do
    unlink "$COMMANDS_DIR/$cmd.md"
  done

  unlink "$SKILLS_DIR/projectask"

  echo ""
  echo -e "${GREEN}Done!${NC} All symlinks removed."
}

case "${1:-install}" in
  install) install ;;
  uninstall) uninstall ;;
  -h|--help) usage ;;
  *) echo -e "${RED}Unknown command: $1${NC}"; usage; exit 1 ;;
esac
