# CLAUDE.md — dotfiles 프로젝트 지침

## 프로젝트 개요
Rey의 개인 dotfiles. chezmoi로 관리하며 Ubuntu(desktop)와 Fedora(laptop) 환경을 통일한다.

## 도구 스택
- **chezmoi** v2.70.1 (`/snap/bin/chezmoi`) — dotfiles 관리자
- **zsh** — 기본 셸
- **starship** — 프롬프트
- **D2Coding Ligature** — 터미널 폰트 (Powerline 기본 심볼만 지원, Nerd Font 미지원)

## chezmoi 규칙
- 소스 디렉터리: `~/.local/share/chezmoi` (= GitHub repo 루트)
- 설정 템플릿: `~/.local/share/chezmoi/.chezmoi.toml.tmpl` → init 시 `~/.config/chezmoi/chezmoi.toml` 자동 생성
- **파일 추가 시**: `chezmoi add <파일>` 또는 소스 디렉터리에 직접 생성 후 `chezmoi apply`
- **확인**: `chezmoi diff` → 문제 없으면 `chezmoi apply`

## 파일 네이밍 규칙 (chezmoi)
| 소스 패턴 | 대상 |
|-----------|------|
| `dot_foo` | `~/.foo` |
| `dot_config/bar` | `~/.config/bar` |
| `dot_foo.tmpl` | `~/.foo` (템플릿 렌더링) |

## 템플릿 변수
```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
  name  = "rey"
  email = "jmy1330@gmail.com"
  role  = "desktop"   # Ubuntu: "desktop" / Fedora: "laptop"
```

OS 분기 예시:
```
{{ if eq .chezmoi.osRelease.id "ubuntu" }}
# Ubuntu 전용 코드
{{ else if eq .chezmoi.osRelease.id "fedora" }}
# Fedora 전용 코드
{{ end }}
```

## 금지 사항
- 셸 설정에 git alias(`g`, `ga`, `gc` 등) 추가 금지
- D2Coding이 지원하지 않는 Nerd Font 아이콘 사용 금지 (starship 설정 포함)
- `~/.zshrc` 등 홈 디렉터리 파일을 chezmoi를 거치지 않고 직접 수정 금지

## 폰트 제약 (starship.toml 작성 시)
D2Coding Ligature가 지원하는 범위:
- Powerline: `` `` `` `` `` `` `` `` (U+E0A0–U+E0B3) ✓
- 일반 유니코드 기호: `❯` `❮` `⇡` `⇣` `⇕` `…` ✓
- Nerd Font 전용 아이콘 (U+E700 이상 PUA 영역 대부분) ✗

## 작업 흐름
```sh
# 파일 수정 후
chezmoi diff          # 변경사항 확인
chezmoi apply         # 홈 디렉터리에 적용
git add -p && git commit   # dotfiles 저장소에 커밋
git push              # GitHub 동기화
```
