# dotfiles

Rey의 개인 환경 설정 파일. [chezmoi](https://www.chezmoi.io/)로 관리한다.

## 환경

| 항목 | 값 |
|------|----|
| OS | Ubuntu (desktop), Fedora (laptop) |
| Shell | zsh |
| Prompt | starship |
| Font | D2Coding Ligature |
| 관리 도구 | chezmoi |

---

## 설치 (새 머신)

```sh
# chezmoi 설치 (Ubuntu)
sudo snap install chezmoi --classic

# chezmoi 설치 (Fedora)
sudo dnf install chezmoi

# dotfiles 초기화
chezmoi init https://github.com/myjung/dotfiles.git

# ~/.config/chezmoi/chezmoi.toml 편집 후 role 값 설정
#   desktop (Ubuntu) 또는 laptop (Fedora)

# 적용
chezmoi apply
```

### starship 설치

```sh
curl -sS https://starship.rs/install.sh | sh
```

---

## 파일 구조

```
dotfiles/
├── dot_zshrc.tmpl                 → ~/.zshrc
└── dot_config/
    ├── shell/
    │   └── common.sh              → ~/.config/shell/common.sh
    └── starship.toml              → ~/.config/starship.toml
```

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

**프롬프트 레이아웃:**

```
[ user ][ @hostname ][ ~/path ][  branch status  ] [took Xs] [HH:MM]
❯
```

| 세그먼트 | 색상 | 내용 |
|----------|------|------|
| 유저명 | `#7aa2f7` on `#1a1b26` | 항상 표시. root일 때 `#1a1b26` on `#f7768e` (빨간 배경 반전) |
| 호스트명 | `#7dcfff` on `#1a1b26` | 항상 표시. SSH 접속 시 `ssh:@hostname` 형태로 prefix 추가 |
| 디렉터리 | `#c0caf5` on `#16213e` | `~` 기준 전체 경로 (최대 10단계, 초과 시 `…/` 생략) |
| git branch | `#7aa2f7` on `#0f3460` | 브랜치명 (` ` Powerline 심볼) |
| git status | 상태별 색상 | `+`staged `~`modified `?`untracked `⇡`ahead `⇣`behind |
| 언어 버전 | 각 언어별 색상 | py: / node: / rs: / go: / java: |
| 소요 시간 | `#565f89` | 2초 이상 명령에만 표시 |
| 시각 | `#565f89` | HH:MM |
| 입력 문자 | 초록/빨강 | `❯` (성공/실패) |

**상황별 프롬프트:**

| 상황 | 표시 |
|------|------|
| 일반 로컬 | `[ rey ][ @hostname ]` |
| SSH 접속 | `[ rey ][ ssh:@hostname ]` |
| root | 빨간 배경 `[ root ][ @hostname ]` |

**주의:** D2Coding Ligature는 Powerline 기본 심볼(U+E0A0–U+E0B3)만 지원한다. Nerd Font 아이콘은 사용하지 않는다.

---

## chezmoi 작업 흐름

```sh
# 현재 상태 확인
chezmoi status

# 변경사항 미리보기
chezmoi diff

# 홈 디렉터리에 적용
chezmoi apply

# 홈의 파일을 소스로 역 추적
chezmoi add ~/.config/some/file

# GitHub 동기화
git add -p && git commit -m "..."
git push
```

### Fedora 노트북 추가 시

`~/.config/chezmoi/chezmoi.toml`에서:
```toml
[data]
  role = "laptop"
```

---

## 관련 링크

- chezmoi 공식 문서: https://www.chezmoi.io/
- starship 공식 문서: https://starship.rs/
- D2Coding 폰트: https://github.com/naver/d2codingfont
