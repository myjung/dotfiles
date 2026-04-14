# setup/

신규 머신용 패키지 설치 스크립트 및 자동화에서 분리한 별도 설치 가이드.

## install.sh

Ubuntu (apt) / Fedora (dnf)를 자동 감지해서 공통 패키지를 설치합니다. 전체 부트스트랩 흐름과 포함 패키지 목록은 [루트 README](../README.md) 참고.

```sh
bash ~/.local/share/chezmoi/setup/install.sh
```

멱등성을 유지하므로 중단 후 재실행 가능. `sudo`가 필요한 구간에서만 권한을 요청합니다.

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
