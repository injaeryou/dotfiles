# dotfiles

Personal config, symlinked into `~` by `./install.sh` (매핑은 `install.sh` 참조).

## Gotcha

- config는 저장소 → `~`로 심링크된다 (예: `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`).
  - 예외: `claude/settings.json`은 심링크가 아니라 `~/.claude/settings.json`에 병합된다 (`scripts/merge_settings.py`). 저장소를 고친 뒤 `./install.sh`를 다시 돌려야 반영된다.
- Edit 툴은 심링크 쓰기를 거부한다. `~/` 경로가 아니라 **저장소 내 실제 경로**를 편집한다.
- `claude/CLAUDE.md`는 전역 개인 규칙(모든 프로젝트 공통)이다. 이 저장소 전용 내용은 여기(root `AGENTS.md`)에 둔다.
