# dotfiles

Personal config, symlinked into `~` by `./install.sh` (매핑은 `install.sh` 참조).

## Gotcha

- config는 저장소 → `~`로 심링크된다 (예: `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`).
  - 예외: `claude/settings.json`은 심링크가 아니라 `~/.claude/settings.json`에 병합된다 (`scripts/merge_settings.py`). 저장소를 고친 뒤 `./install.sh`를 다시 돌려야 반영된다.
- Edit 툴은 심링크 쓰기를 거부한다. `~/` 경로가 아니라 **저장소 내 실제 경로**를 편집한다.
- 전역 개인 규칙(모든 프로젝트 공통)은 `claude/rules/*.md`, 절차는 `claude/skills/<name>/SKILL.md`에 둔다. 이 저장소 전용 내용은 여기(root `AGENTS.md`)에 둔다.
  - `rules/`는 폴더째, `skills/`는 스킬 폴더 단위로 심링크된다 (`~/.claude/skills`에 플러그인 스킬이 같이 있음).
