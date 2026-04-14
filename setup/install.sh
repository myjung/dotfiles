#!/usr/bin/env bash
# Ubuntu / Fedora 공통 개발환경 설치 스크립트
# 배포판 감지 후 패키지 매니저 분기만 수행
set -euo pipefail

# ===== 유틸 =====
log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# ===== 배포판 감지 =====
if command -v apt >/dev/null; then
  DISTRO=ubuntu
elif command -v dnf >/dev/null; then
  DISTRO=fedora
else
  echo "지원하지 않는 배포판이에요 (apt/dnf 필요)." >&2
  exit 1
fi
log "배포판: $DISTRO"

sudo -v

# ===== 배포판별 준비 =====
case "$DISTRO" in
  ubuntu)
    log "apt 업데이트"
    sudo apt update
    ;;
  fedora)
    log "RPM Fusion free/nonfree 저장소 등록"
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
      || warn "RPM Fusion 이미 등록되어 있거나 실패 — 계속 진행"
    ;;
esac

# ===== 기본 빌드/CLI 도구 =====
log "빌드 도구 + git/zsh/tmux/jq/curl/wget/unzip 설치"
case "$DISTRO" in
  ubuntu)
    sudo apt install -y \
      build-essential git zsh tmux jq curl wget unzip \
      ca-certificates gnupg software-properties-common apt-transport-https
    ;;
  fedora)
    sudo dnf group install -y development-tools
    sudo dnf install -y \
      git zsh tmux jq curl wget unzip \
      ca-certificates dnf-plugins-core
    ;;
esac

# ===== glow (markdown 뷰어) =====
log "glow 설치"
case "$DISTRO" in
  ubuntu)
    if ! command -v glow >/dev/null; then
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
      echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
      sudo apt update
      sudo apt install -y glow
    else
      log "glow 이미 설치됨 — 건너뜀"
    fi
    ;;
  fedora)
    sudo dnf install -y glow
    ;;
esac

# ===== Noto CJK KR =====
log "Noto CJK KR 설치"
case "$DISTRO" in
  ubuntu)
    sudo apt install -y fonts-noto-cjk fonts-noto-cjk-extra
    ;;
  fedora)
    sudo dnf install -y \
      google-noto-sans-cjk-vf-fonts \
      google-noto-serif-cjk-vf-fonts \
      google-noto-sans-mono-cjk-vf-fonts || \
    sudo dnf install -y \
      google-noto-sans-cjk-fonts \
      google-noto-serif-cjk-fonts \
      google-noto-sans-mono-cjk-fonts
    ;;
esac

# ===== D2Coding Nerd Font Ligature (공통) =====
log "D2Coding Nerd Font Ligature 설치 (한글 + Nerd 아이콘 + 리가처 통합)"
if ! fc-list | grep -qi "D2Coding.*Nerd"; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/d2coding.tar.xz" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/D2Coding.tar.xz"
  mkdir -p "$tmp/extract"
  tar -xf "$tmp/d2coding.tar.xz" -C "$tmp/extract"
  sudo mkdir -p /usr/local/share/fonts/d2coding-nerd
  sudo find "$tmp/extract" -iname "D2CodingLigature*.ttf" -exec cp {} /usr/local/share/fonts/d2coding-nerd/ \;
  rm -rf "$tmp"
else
  log "D2Coding Nerd Font 이미 설치됨 — 건너뜀"
fi
log "폰트 캐시 갱신"
sudo fc-cache -f

# ===== 한글 입력기 =====
log "ibus-hangul 설치"
case "$DISTRO" in
  ubuntu) sudo apt install -y ibus ibus-hangul ;;
  fedora) sudo dnf install -y ibus ibus-hangul ;;
esac

# ===== VS Code =====
log "VS Code 설치"
if ! command -v code >/dev/null; then
  case "$DISTRO" in
    ubuntu)
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
      echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
      sudo apt update
      sudo apt install -y code
      ;;
    fedora)
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
      sudo dnf install -y code
      ;;
  esac
else
  log "VS Code 이미 설치됨 — 건너뜀"
fi

# ===== Google Chrome =====
log "Google Chrome 설치"
if ! command -v google-chrome >/dev/null; then
  case "$DISTRO" in
    ubuntu)
      tmp=$(mktemp -d)
      curl -fsSL -o "$tmp/chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      sudo apt install -y "$tmp/chrome.deb"
      rm -rf "$tmp"
      ;;
    fedora)
      sudo dnf install -y fedora-workstation-repositories || true
      sudo dnf config-manager setopt google-chrome.enabled=1 2>/dev/null || \
        sudo dnf config-manager --set-enabled google-chrome
      sudo dnf install -y google-chrome-stable || {
        warn "fedora-workstation-repositories 경로 실패 — google repo 직접 등록"
        sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
        sudo dnf install -y google-chrome-stable
      }
      ;;
  esac
else
  log "Chrome 이미 설치됨 — 건너뜀"
fi

# ===== uv (Python) =====
log "uv 설치"
if ! command -v uv >/dev/null && [ ! -x "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  log "uv 이미 설치됨 — 건너뜀"
fi

# ===== nvm =====
log "nvm 설치"
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  log "nvm 이미 설치됨 — 건너뜀"
fi

# ===== starship =====
log "starship 설치"
if ! command -v starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  log "starship 이미 설치됨 — 건너뜀"
fi

# ===== 마무리 =====
cat <<'EOF'

===============================================
패키지 설치 완료. 다음 단계를 수동으로 진행하세요:

1. zsh를 기본 셸로:
     chsh -s "$(which zsh)"

2. Node 설치 후 Claude Code:
     source ~/.nvm/nvm.sh
     nvm install --lts
     npm install -g @anthropic-ai/claude-code

3. ibus-hangul 적용을 위해 로그아웃/재로그인.

zsh/starship/nvm 초기화는 chezmoi가 적용한 ~/.zshrc에
이미 포함되어 있어요 (수동 편집 불필요).
===============================================
EOF
