#!/bin/bash

# Dotfiles setup script for macOS
# Installs tools, symlinks configs, and gets a fresh Mac ready.

set -e
trap 'echo -e "\n${RED}[ERROR]${NC} Script interrupted."; exit 1' INT TERM

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_ONLY=false
if [[ "${1:-}" == "--link" ]]; then
    LINK_ONLY=true
fi

# ── Sanity checks ──────────────────────────────────────────────────

if [[ "$OSTYPE" != darwin* ]]; then
    err "This script is for macOS only."
    exit 1
fi

if ! $LINK_ONLY && ! xcode-select -p &>/dev/null; then
    err "Xcode Command Line Tools are required. Install them with: xcode-select --install"
    exit 1
fi

if [[ ! -d "$DOTFILES_DIR/home" ]] || [[ ! -d "$DOTFILES_DIR/config" ]]; then
    err "Run this from the dotfiles repo root."
    exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────

backup_and_link() {
    local src="$1" dest="$2"
    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
        local bak="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up $dest -> $bak"
        mv "$dest" "$bak"
    elif [[ -L "$dest" ]]; then
        rm "$dest"
    fi
    ln -s "$src" "$dest"
    ok "Linked $(basename "$dest")"
}

if ! $LINK_ONLY; then
# ── 1. Homebrew ────────────────────────────────────────────────────

info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    ok "Homebrew already installed"
fi

# ── 2. Brew packages ──────────────────────────────────────────────

FORMULAE=(
    eza
    gh
    git-lfs
    node
    openssl
    oven-sh/bun/bun
    pyenv
    readline
    sqlite3
    tmux
    tree
    uv
    xz
    zlib
)

CASKS=(
    font-hack-nerd-font
    kitty
)

info "Installing brew formulae..."
for pkg in "${FORMULAE[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        ok "$pkg (already installed)"
    else
        info "Installing $pkg..."
        brew install "$pkg"
    fi
done

info "Installing brew casks..."
for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        ok "$cask (already installed)"
    else
        info "Installing $cask..."
        brew install --cask "$cask" || warn "$cask already exists, skipping"
    fi
done

# ── 3. Fonts ──────────────────────────────────────────────────────

FONT_DIR="$HOME/Library/Fonts"
info "Installing fonts..."

if ls "$FONT_DIR"/IBMPlexMono-*.ttf &>/dev/null; then
    ok "IBM Plex Mono already installed"
else
    info "Installing IBM Plex Mono..."
    TMPDIR_FONT="$(mktemp -d)"
    curl -sL "https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-mono%401.1.0/ibm-plex-mono.zip" -o "$TMPDIR_FONT/ibm-plex-mono.zip"
    unzip -qo "$TMPDIR_FONT/ibm-plex-mono.zip" -d "$TMPDIR_FONT/ibm-plex-mono"
    find "$TMPDIR_FONT/ibm-plex-mono" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
    rm -rf "$TMPDIR_FONT"
    ok "IBM Plex Mono installed"
fi

# ── 4. Oh My Zsh + plugins + themes ──────────────────────────────

info "Setting up Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
else
    ok "Oh My Zsh already installed"
fi

OMZ_CUSTOM="$HOME/.oh-my-zsh/custom"

# Plugins
# Pinned versions — update these when you want to upgrade
AUTOSUGGESTIONS_TAG="v0.7.1"
SYNTAX_HIGHLIGHTING_TAG="0.8.0"
P10K_TAG="v1.20.0"

install_zsh_plugin() {
    local name="$1" url="$2" tag="$3"
    if [[ ! -d "$OMZ_CUSTOM/plugins/$name" ]]; then
        info "Installing $name@$tag..."
        git clone --quiet --branch "$tag" --depth=1 "$url" "$OMZ_CUSTOM/plugins/$name"
        ok "$name@$tag installed"
    else
        ok "$name already installed"
    fi
}

install_zsh_plugin zsh-autosuggestions \
    https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_TAG"
install_zsh_plugin zsh-syntax-highlighting \
    https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_HIGHLIGHTING_TAG"

# Themes
if [[ ! -d "$OMZ_CUSTOM/themes/powerlevel10k" ]]; then
    info "Installing Powerlevel10k@$P10K_TAG..."
    git clone --quiet --branch "$P10K_TAG" --depth=1 \
        https://github.com/romkatv/powerlevel10k.git "$OMZ_CUSTOM/themes/powerlevel10k"
    ok "Powerlevel10k@$P10K_TAG installed"
else
    ok "Powerlevel10k already installed"
fi

fi # end LINK_ONLY guard for sections 1-4

# ── 5. Symlink home dotfiles ─────────────────────────────────────

info "Linking home dotfiles..."

HOME_FILES=(.zshrc .zprofile .p10k.zsh .vimrc)
for file in "${HOME_FILES[@]}"; do
    if [[ -f "$DOTFILES_DIR/home/$file" ]]; then
        backup_and_link "$DOTFILES_DIR/home/$file" "$HOME/$file"
    else
        warn "$file not found in dotfiles/home/"
    fi
done

if ! $LINK_ONLY; then
# ── 6. Git config from template ──────────────────────────────────

info "Setting up .gitconfig..."
if [[ -f "$DOTFILES_DIR/home/.gitconfig.template" ]]; then
    existing_name="$(git config --global user.name 2>/dev/null || echo '')"
    existing_email="$(git config --global user.email 2>/dev/null || echo '')"

    read -rp "Git user name [$existing_name]: " git_name
    git_name="${git_name:-$existing_name}"

    read -rp "Git email [$existing_email]: " git_email
    git_email="${git_email:-$existing_email}"

    if [[ -f "$HOME/.gitconfig" ]] && [[ ! -L "$HOME/.gitconfig" ]]; then
        mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    sed "s/{{USER_NAME}}/$git_name/g; s/{{USER_EMAIL}}/$git_email/g" \
        "$DOTFILES_DIR/home/.gitconfig.template" > "$HOME/.gitconfig"
    ok ".gitconfig generated"
fi
fi # end LINK_ONLY guard for section 6

# ── 7. Symlink config directories ────────────────────────────────

info "Linking config directories..."
mkdir -p "$HOME/.config"

CONFIG_DIRS=(kitty git)
for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$DOTFILES_DIR/config/$dir" ]]; then
        backup_and_link "$DOTFILES_DIR/config/$dir" "$HOME/.config/$dir"
    else
        warn "config/$dir not found in dotfiles"
    fi
done

# gh config — copy file only, not the directory (hosts.yml contains auth tokens)
mkdir -p "$HOME/.config/gh"
if [[ -f "$DOTFILES_DIR/config/gh/config.yml" ]]; then
    cp "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"
    ok "Copied gh config.yml"
fi

# ── 8. Install wt command ────────────────────────────────────────

info "Installing wt command..."
mkdir -p "$HOME/.local/bin"
backup_and_link "$DOTFILES_DIR/bin/wt" "$HOME/.local/bin/wt"
chmod +x "$DOTFILES_DIR/bin/wt"

# Ensure ~/.local/bin is on PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    warn "~/.local/bin is not on PATH. It will be after shell restart (set in .zprofile)."
fi

if ! $LINK_ONLY; then
# ── 9. Python via pyenv ──────────────────────────────────────────

info "Setting up pyenv global Python..."
eval "$(pyenv init -)"
PYTHON_VERSION="3.13.3"
if pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
    ok "Python $PYTHON_VERSION already installed"
else
    info "Installing Python $PYTHON_VERSION via pyenv..."
    pyenv install "$PYTHON_VERSION"
    ok "Python $PYTHON_VERSION installed"
fi
pyenv global "$PYTHON_VERSION"
ok "pyenv global set to $PYTHON_VERSION"

# ── 10. Git LFS ──────────────────────────────────────────────────

info "Setting up Git LFS..."
git lfs install
ok "Git LFS initialized"

# ── 11. Google Cloud SDK (optional) ──────────────────────────────

if [[ ! -d "$HOME/google-cloud-sdk" ]]; then
    echo ""
    read -rp "Install Google Cloud SDK? [y/N]: " install_gcloud
    if [[ "$install_gcloud" =~ ^[Yy]$ ]]; then
        curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
        ok "Google Cloud SDK installed"
    else
        info "Skipping Google Cloud SDK (install later: curl https://sdk.cloud.google.com | bash)"
    fi
else
    ok "Google Cloud SDK already installed"
fi
fi # end LINK_ONLY guard for sections 9-11

# ── Done ──────────────────────────────────────────────────────────

echo ""
if $LINK_ONLY; then
    source "$HOME/.zshrc"
    echo -e "${GREEN}Symlinks updated and shell reloaded!${NC}"
else
    echo -e "${GREEN}Setup complete!${NC}"
fi
echo ""
if ! $LINK_ONLY; then
echo "Installed:"
echo "  - Homebrew packages: ${FORMULAE[*]}"
echo "  - Casks: ${CASKS[*]}"
echo "  - Fonts: IBM Plex Mono, Hack Nerd Font"
echo "  - Oh My Zsh + Powerlevel10k"
echo "  - Plugins: zsh-autosuggestions, zsh-syntax-highlighting"
echo "  - Dotfiles symlinked"
echo "  - wt worktree command"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or: source ~/.zshrc)"
echo "  2. Kitty is installed — launch it and your config will load"
echo "  3. Install a window manager of your choice"
fi
echo ""
