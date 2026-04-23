---
name: vault
description: Use this skill in external (non-vault) project sessions to pull personal knowledge from the user's local LLM knowledge vault at ~/knowledge-vault, and to drop new notes back to its inbox. Trigger when the user runs /vault, or when a query references personal context (identity, past decisions, prior projects, preferences, glossary terms) that likely lives in the vault. The skill is read-only for wiki; writes go only to raw/inbox/ via `vault inbox` with user approval.
---

# Vault — 개인 LLM 지식 Vault CLI

이 머신에 사용자의 개인 LLM 지식 vault가 있다. 위치는 `$VAULT_ROOT` (기본값 `~/knowledge-vault`). `vault` CLI (`~/.local/bin/vault`, PATH에 등록됨) 로 read-only 접근과 inbox drop이 가능하다.

이 skill은 **vault 밖 프로젝트 세션**에서 사용된다. vault 자체 작업 중이면 이 skill 대신 `CLAUDE.md`를 직접 읽는다.

## 세션 시작 시

skill 활성화 직후 다음을 실행하여 사용자 profile과 vault 운영 규약을 적재한다:

```bash
vault context
```

출력에는 `wiki/entities/me/profile.md` (사용자 identity·경력·프로젝트)와 `wiki/meta/quickref.md` (vault 운영 원칙 축약본)가 포함된다. quickref의 규칙(Navigation Protocol, Ownership Model, Cognitive Guardrails 등)은 이 외부 세션에도 적용된다.

## 읽기 명령

| 명령 | 용도 |
|---|---|
| `vault context` | profile + quickref (세션 부트스트랩) |
| `vault quickref` | vault 운영 규약 축약본만 |
| `vault index` | wiki 카탈로그 |
| `vault search <query>` | wiki 전체 grep (파일명·본문·frontmatter) |
| `vault show <page>` | 페이지 전체 출력 (경로 또는 basename 허용) |
| `vault glossary [term]` | 용어집 조회 |
| `vault log [-n N]` | 최근 N개 변경 로그 |

사용 원칙:

- **Summoning 우선:** 미리 대량 주입하지 말고, 사용자 질의가 개인 맥락을 필요로 할 때만 `vault search` / `vault show` 로 조회.
- **명시 인용:** vault 근거로 답할 때는 어느 페이지에서 가져온 정보인지 경로를 명시. 예: `[[entities/me/profile]] §Work Experience`.
- **LLM 생성 구분:** vault에 근거가 없으면 "(vault에 근거 없음, LLM 생성)" 으로 답변 안에 표기.
- **Frontmatter 우선 확인:** 페이지 내용으로 답하기 전 `status` / `last_verified` / `supersedes` 점검 (quickref Navigation Protocol 참조).

## 쓰기 명령 (inbox drop만)

작업 중 vault에 보존할 가치가 있는 지식(새 개념·과거 결정·재사용 가능한 합성·외부 프로젝트에서 얻은 통찰 등)이 생기면, **사용자에게 제안**하고 승인 후 drop한다:

```bash
vault inbox "<title>"                  # $EDITOR 실행
vault inbox "<title>" -m "본문"        # 인라인 인자
echo "본문" | vault inbox "<title>"    # stdin
```

drop된 파일은 `raw/inbox/YYYY-MM-DD-<slug>.md` 로 저장된다.

## 금지 사항

- **wiki/ 직접 수정 금지.** `vault` CLI에는 wiki 쓰기 명령이 없다. 직접 파일을 편집하지 말 것. 정식 ingest(wiki 페이지 생성/갱신)는 vault 디렉토리에서의 별도 세션으로 수행된다.
- **사용자 승인 없이 `vault inbox` 자동 실행 금지.** 항상 무엇을 drop할지 보여주고 승인받는다.
- **vault 내용 요약·편집 후 drop 금지.** inbox에는 원본 그대로 drop. 요약·합성은 vault 세션의 ingest 단계에서.
- **wiki 파일 직접 `cat` / `Read` 금지.** CLI 경유가 원칙. CLI 우회는 진화 경로 측정을 왜곡한다.

## 상세

설계 배경과 진화 경로는 vault 내부 `CLAUDE.md §13 Cross-project Consumption` 참조. Auto-pull hook, Auto-push hook, MCP server로의 전환은 Phase 1+ 영역이며 현재는 `/vault` 명시 호출 + 사용자 주도 `vault inbox` 패턴으로 운영된다.
