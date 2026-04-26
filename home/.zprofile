if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# pyenv — global python outside of UV-managed projects
command -v pyenv &>/dev/null && eval "$(pyenv init -)"


# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# UV / local bin
export PATH="$HOME/.local/bin:$PATH"

# UV shell completions
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
