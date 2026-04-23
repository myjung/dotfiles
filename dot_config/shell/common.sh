# ===== PATH =====
export PATH="$HOME/.local/bin:$PATH"

# ===== 편집기 =====
export EDITOR="${EDITOR:-vi}"
export VISUAL="$EDITOR"

# ===== XDG =====
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ===== nvm =====
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ===== 별칭: 파일 목록 =====
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alFt'        # 최근 수정순 정렬

# ===== 별칭: 검색 =====
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ===== 별칭: 디렉터리 이동 =====
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias kv='cd ~/knowledge-vault'

# ===== 별칭: 기타 =====
alias cls='clear'
alias path='echo $PATH | tr ":" "\n"'   # PATH를 한 줄씩 출력
alias reload='exec zsh'                  # zsh 재시작
alias zshconfig='$EDITOR ~/.zshrc'
