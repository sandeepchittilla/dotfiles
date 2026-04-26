# Dotfiles

macOS dotfiles: Zsh, Homebrew, Kitty, pyenv, and dev tools.

## Prerequisites

- macOS
- Xcode Command Line Tools (`xcode-select --install`)

## Quick Start

```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

Restart your terminal when done.

### Updating Symlinks Only

After pulling changes to config files, re-link without re-running the full setup:

```bash
./setup.sh --link
```

This only refreshes symlinks for home dotfiles, config directories, `gh` config, and the `wt` command. Skips Homebrew, fonts, Oh My Zsh, pyenv, git config prompts, and everything else.

## What the Script Does

1. Installs **Homebrew** if missing
2. Installs brew formulae: eza, gh, git-lfs, node, bun, pyenv, tmux, tree, uv (plus pyenv build deps: openssl, readline, sqlite3, xz, zlib)
3. Installs brew casks: kitty, font-hack-nerd-font
4. Installs **IBM Plex Mono** font from GitHub
5. Installs **Oh My Zsh** with Powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting (pinned versions)
6. Symlinks home dotfiles (`.zshrc`, `.zprofile`, `.p10k.zsh`, `.vimrc`)
7. Generates `.gitconfig` from template (prompts for name and email)
8. Symlinks config directories (`kitty`, `git`) and copies `gh` config
9. Installs `wt` worktree helper to `~/.local/bin`
10. Installs **Python 3.13.3** via pyenv
11. Sets up **Git LFS**
12. Optionally installs **Google Cloud SDK**

Existing files are backed up with timestamps (e.g. `~/.zshrc.backup.20240101_120000`) before being replaced.

## Directory Structure

```
dotfiles/
├── bin/
│   └── wt                    # Git worktree helper
├── config/
│   ├── gh/                   # GitHub CLI config (copied, not symlinked)
│   ├── git/                  # Git global ignore
│   └── kitty/                # Kitty terminal theme and config
├── home/
│   ├── .gitconfig.template   # Git config with placeholder name/email
│   ├── .p10k.zsh             # Powerlevel10k prompt config
│   ├── .vimrc                # Vim config
│   ├── .zprofile             # Login shell setup (Homebrew, pyenv, PATH)
│   └── .zshrc                # Interactive shell config (Oh My Zsh, plugins)
├── setup.sh
└── README.md
```

## Post-Install

- Run `p10k configure` to reconfigure the prompt
- Set Kitty (or your terminal) font to **Hack Nerd Font** for proper icons
- The `wt` command is available after restart -- run `wt --help` for usage
