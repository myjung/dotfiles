# setup/

신규 머신용 패키지 설치 스크립트 및 자동화에서 분리한 별도 설치 가이드.

## install.sh

Ubuntu (apt) / Fedora (dnf)를 자동 감지해서 공통 패키지를 설치합니다. 전체 부트스트랩 흐름과 포함 패키지 목록은 [루트 README](../README.md) 참고.

```sh
bash ~/.local/share/chezmoi/setup/install.sh
```

멱등성을 유지하므로 중단 후 재실행 가능. `sudo`가 필요한 구간에서만 권한을 요청합니다.

---

## install.ps1 (Windows)

일반 권한 PowerShell에서 실행해요. 관리자 권한이 필요한 구간(winget, 시스템 설정)은 스크립트가 UAC 창으로 따로 띄워요.

```powershell
powershell -ExecutionPolicy Bypass -File $HOME\.local\share\chezmoi\setup\install.ps1
```

| 단계 | 내용 |
|---|---|
| scoop | 설치 → `no_junction` 켜기 → 버킷(extras, java, nerd-fonts) → 앱 |
| 런타임 | `uv python install 3.13 --default`, `nvm install lts` |
| winget (관리자) | 1Password, Epic Games Launcher, Visual Studio 2026 (UE 5.8 구성 요소) |
| 시스템 (관리자) | 빠른 시작·최대 절전 끄기, 개발자 모드, OpenSSH 서버 + 기본 셸 pwsh |

파일은 **BOM 있는 UTF-8**로 저장해야 해요. Windows PowerShell 5.1은 BOM이 없으면 한글을 CP949로 읽어서 주석 뒤의 코드 줄이 깨져요.

### 수동 단계

**sshd 접속 키 등록.** 관리자 계정은 `~\.ssh\authorized_keys`가 아니라 아래 파일을 읽어요. 키는 1Password에서 만들고 공개 키만 가져와요.

```powershell
# 관리자 PowerShell
$f = 'C:\ProgramData\ssh\administrators_authorized_keys'
op read "op://Personal/<항목>/public key" | Add-Content $f -Encoding ascii
icacls $f /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'   # Administrators, SYSTEM만
```

**OBS 가상 카메라.** scoop OBS는 등록이 안 된 상태로 설치돼요. `no_junction`이라 `current`가 아닌 버전 경로로 등록되므로, OBS를 업데이트하면 다시 등록해야 해요.

```powershell
# 관리자 PowerShell
$d = (Resolve-Path "$env:USERPROFILE\scoop\apps\obs-studio\*\core\win-dshow\data" | Select-Object -Last 1).Path
regsvr32 /i /s "$d\obs-virtualcam-module32.dll"
regsvr32 /i /s "$d\obs-virtualcam-module64.dll"
```

**OBS Spout 플러그인.** [obs-spout2-plugin](https://github.com/Off-World-Live/obs-spout2-plugin) 릴리스의 파일을 scoop persist에 넣어요 (`~\scoop\persist\obs-studio\obs-plugins\64bit\`에 dll, `~\scoop\persist\obs-studio\data\obs-plugins\win-spout\`에 locale).

**Claude Code** (Windows):

```powershell
irm https://claude.ai/install.ps1 | iex
```

---

## Wine + KakaoTalk 별도 설치

Wine 저장소 상황이 배포판 버전마다 달라(특히 Ubuntu 25.10의 WoW64 구조 변경, 26.04는 WineHQ 저장소 아직 없음) 자동화에서 분리. KakaoTalk 용도면 배포판 기본 저장소의 wine으로 충분합니다.

### 설치

**Ubuntu:**
```sh
sudo apt install -y wine winetricks
```

**Fedora:**
```sh
sudo dnf install -y wine winetricks
```

### KakaoTalk 절차

Ubuntu 25.10+ / 최신 Fedora의 Wine은 **WoW64 빌드**라 64비트 prefix 하나에서 32비트 앱을 실행해요. 기존 `WINEARCH=win32` 방식은 더 이상 사용하지 않습니다.

```sh
WINEPREFIX=~/.wine-kakao winecfg
WINEPREFIX=~/.wine-kakao winetricks cjkfonts
WINEPREFIX=~/.wine-kakao wine KakaoTalk_Setup.exe
```

**주의사항:**
- Ubuntu 24.04 이하에서 쓰던 `WINEARCH=win32` prefix는 WoW64 Wine과 호환 안 됨. 기존 prefix 삭제 후 재설치 필요.
- `winetricks cjkfonts`로 한글이 해결 안 되면 prefix의 `drive_c/windows/Fonts/`에 D2Coding.ttf 직접 복사 후 `winecfg`에서 라이브러리 대체 폰트 지정.
- WineHQ 최신판이 필요하면(Ubuntu만) https://wiki.winehq.org/Ubuntu 참고. 26.04(resolute)는 아직 저장소 없음.

---

## Docker 별도 설치

배포판 릴리스 직후 Docker 공식 저장소 동기화가 지연되는 경우가 있어 자동화에서 분리.

### Ubuntu (25.10 / 26.04)

공식 가이드: https://docs.docker.com/engine/install/ubuntu/

```sh
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg 2>/dev/null
done

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

26.04 릴리스 직후 `resolute` 저장소가 없으면 폴백:
```sh
sudo apt install -y docker.io docker-compose-v2
```

### Fedora (43 / 44)

공식 가이드: https://docs.docker.com/engine/install/fedora/

```sh
sudo dnf remove -y docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
  docker-engine-selinux docker-engine 2>/dev/null

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

F44 패키지가 아직 없으면 F43으로 폴백:
```sh
sudo sed -i 's|\$releasever|43|g' /etc/yum.repos.d/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 확인

```sh
newgrp docker
docker run hello-world
docker compose version
```

---

## Claude Code (별도)

```sh
source ~/.nvm/nvm.sh
nvm install --lts
npm install -g @anthropic-ai/claude-code
```

---

## diceware.sh

EFF large wordlist 기반 패스프레이즈 생성기. 가끔 사용.

```sh
bash setup/diceware.sh          # 7단어 기본
bash setup/diceware.sh 10       # 10단어
bash setup/diceware.sh -n 6     # -n 플래그도 가능
```

기각 샘플링으로 편향 없이 `/dev/urandom`에서 단어 인덱스를 뽑습니다. `eff_large_wordlist.txt`는 저장소에 포함되어 있어 네트워크 없이 동작.
