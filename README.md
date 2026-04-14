# dotfiles

Rey의 개인 환경 설정. [chezmoi](https://www.chezmoi.io/)로 관리하며 Ubuntu(desktop)와 Fedora(laptop)를 통일한다.

## 환경

| 항목 | 값 |
|------|----|
| OS | Ubuntu 25.10 / 26.04 LTS (desktop), Fedora 43 / 44 (laptop) |
| Shell | zsh |
| Prompt | starship |
| Font | D2Coding Nerd Font (Ligature) — 한글 + Nerd 아이콘 + 리가처 통합 |
| 관리 도구 | chezmoi |

---

## 신규 머신 세팅

```sh
# 1. chezmoi 설치 + dotfiles clone + apply (role 프롬프트 포함)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply myjung

# 2. 패키지 설치 (Ubuntu/Fedora 자동 감지)
bash ~/.local/share/chezmoi/setup/install.sh

# 3. zsh 기본 셸 전환 + Node/Claude Code 설치 + 로그아웃 재로그인
#    (스크립트 말미 안내 참고)
```

1단계가 `chezmoi` 바이너리 설치와 `~/.local/share/chezmoi`로의 clone, 홈 디렉터리 적용까지 한 번에 처리합니다. `role`(desktop/laptop)을 프롬프트로 물어보고 `~/.config/chezmoi/chezmoi.toml`을 자동 생성해요.

---

## 파일 구조

```
~/.local/share/chezmoi/   (= GitHub repo 루트)
├── .chezmoi.toml.tmpl             → ~/.config/chezmoi/chezmoi.toml (init 시 자동 생성)
├── dot_zshrc.tmpl                 → ~/.zshrc
├── dot_config/
│   ├── shell/common.sh            → ~/.config/shell/common.sh
│   └── starship.toml              → ~/.config/starship.toml
└── setup/                         패키지 설치 스크립트 (chezmoi 무시)
    ├── install.sh                 Ubuntu/Fedora 공통 설치
    ├── README.md                  Docker/Wine 등 별도 설치 안내
    ├── diceware.sh                가끔 쓰는 패스프레이즈 생성기
    └── eff_large_wordlist.txt
```

`setup/` 같은 일반 폴더는 chezmoi가 무시하므로 홈으로 복사되지 않습니다.

---

## 포함 패키지 (`setup/install.sh`)

| 범주 | 항목 |
|---|---|
| 폰트 | D2Coding Nerd Font Ligature, Noto CJK KR (Sans/Serif/Mono) |
| 입력기 | ibus-hangul |
| 에디터/툴 | VS Code, git, zsh, starship, tmux, jq, glow |
| 런타임 | uv (Python), nvm (Node) |
| 기타 | Google Chrome, build-essential / Development Tools |

Docker, Wine, Claude Code는 별도 — [setup/README.md](./setup/README.md) 참고.

스크립트는 `sudo`가 필요한 구간에서만 권한을 요청하고, 멱등성을 유지하여 중단 후 재실행해도 안전합니다.

---

## 설정 상세

### zsh (`dot_zshrc.tmpl`)

| 설정 | 내용 |
|------|------|
| `AUTO_CD` | 디렉터리명만 입력해도 이동 |
| `AUTO_PUSHD` | `cd` 시 dirstack 자동 기록 |
| `SHARE_HISTORY` | 세션 간 히스토리 공유 |
| `HIST_IGNORE_DUPS` | 중복 명령 저장 안 함 |
| `bindkey -e` | Emacs 키 바인딩 |
| 위/아래 화살표 | 히스토리 접두어 검색 |
| sdkman | Ubuntu에서만 로드 (템플릿 분기) |

### 공통 환경 (`dot_config/shell/common.sh`)

| 항목 | 값 |
|------|----|
| `EDITOR` | vim |
| nvm | `~/.nvm` 자동 로드 |

**별칭:**

| 별칭 | 설명 |
|------|------|
| `ll` | `ls -alF` |
| `la` | `ls -A` |
| `lt` | `ls -alFt` (최근 수정순) |
| `..` / `...` / `....` | 상위 디렉터리 이동 |
| `cls` | 화면 지우기 |
| `path` | `$PATH`를 한 줄씩 출력 |
| `reload` | zsh 재시작 |
| `zshconfig` | `$EDITOR ~/.zshrc` |

### starship 프롬프트 (`dot_config/starship.toml`)

**색상 테마:** Tokyo Night

```
[ user ][ @hostname ][ ~/path ][  branch status  ] [took Xs] [HH:MM]
❯
```

| 세그먼트 | 색상 | 내용 |
|----------|------|------|
| 유저명 | `#7aa2f7` on `#1a1b26` | 항상 표시. root일 때 `#1a1b26` on `#f7768e` (빨간 배경 반전) |
| 호스트명 | `#7dcfff` on `#1a1b26` | 항상 표시. SSH 접속 시 `ssh:@hostname` prefix |
| 디렉터리 | `#c0caf5` on `#16213e` | `~` 기준 전체 경로 (최대 10단계, 초과 시 `…/` 생략) |
| git branch | `#7aa2f7` on `#0f3460` | 브랜치명 (Powerline 심볼) |
| git status | 상태별 색상 | `+`staged `~`modified `?`untracked `⇡`ahead `⇣`behind |
| 언어 버전 | 각 언어별 색상 | py: / node: / rs: / go: / java: |
| 소요 시간 | `#565f89` | 2초 이상 명령에만 표시 |
| 시각 | `#565f89` | HH:MM |
| 입력 문자 | 초록/빨강 | `❯` (성공/실패) |

---

## chezmoi 작업 흐름

```sh
# 소스 디렉터리로 이동 후 편집
chezmoi cd
$EDITOR dot_config/starship.toml

# 변경사항 확인 → 적용
chezmoi diff
chezmoi apply

# 다른 머신에서 받기
chezmoi update   # git pull + apply

# git 커밋 + 푸시
git add -p && git commit -m "..."
git push
```

### 자주 쓰는 명령

| 명령 | 용도 |
|---|---|
| `chezmoi diff` | 소스 ↔ 홈 차이 미리보기 |
| `chezmoi apply` | 소스를 홈에 반영 |
| `chezmoi add <파일>` | 홈의 파일을 소스로 가져오기 |
| `chezmoi edit <파일>` | 소스 파일을 에디터로 열기 |
| `chezmoi cd` | 소스 디렉터리로 이동 (서브셸) |
| `chezmoi update` | git pull + apply 한 번에 |

### 파일 네이밍 규칙

| 소스 패턴 | 대상 |
|-----------|------|
| `dot_foo` | `~/.foo` |
| `dot_config/bar` | `~/.config/bar` |
| `dot_foo.tmpl` | `~/.foo` (템플릿 렌더링) |

### OS 분기 (템플릿)

```
{{ if eq .chezmoi.osRelease.id "ubuntu" -}}
# Ubuntu 전용
{{ else if eq .chezmoi.osRelease.id "fedora" -}}
# Fedora 전용
{{ end -}}
```

---

## 관련 링크

- chezmoi: https://www.chezmoi.io/
- starship: https://starship.rs/
- D2Coding Nerd Fonts: https://github.com/ryanoasis/nerd-fonts
- D2Coding 원본: https://github.com/naver/d2codingfont
