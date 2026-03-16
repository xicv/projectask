#!/usr/bin/env bash
set -euo pipefail

# projectask installer
# Creates symlinks in ~/.claude/skills for projectask skills
#
# Gives: /projectask:create, /projectask:list, /projectask:done, /projectask:start

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
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

  mkdir -p "$SKILLS_DIR"

  # Skills — gives /projectask:create, /projectask:list, /projectask:done, /projectask:start
  for skill in create list done start; do
    link "$REPO_DIR/skills/$skill" "$SKILLS_DIR/projectask:$skill"
  done

  echo ""
  echo -e "${GREEN}Done!${NC} 4 skills installed."
  echo ""
  echo "  /projectask:create  /projectask:list  /projectask:done  /projectask:start"
}

uninstall() {
  echo "Uninstalling projectask..."
  echo ""

  # Remove skill symlinks (colon format)
  for skill in create list done start; do
    unlink "$SKILLS_DIR/projectask:$skill"
  done

  # Clean up old symlink formats if present
  for skill in create list done start; do
    unlink "$SKILLS_DIR/projectask-$skill"
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
