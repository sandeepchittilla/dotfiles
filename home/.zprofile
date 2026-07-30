if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# UV / local bin
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

# Everything else (pyenv, gcloud, completions) lives in .zshrc so it runs
# after the p10k instant prompt has already painted.
