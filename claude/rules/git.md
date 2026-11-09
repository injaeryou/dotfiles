## Git 커밋

### 메시지

- 저장소에 커밋 컨벤션이 있으면 그걸 따른다 — 아래 기본값보다 우선한다.
  - 찾을 곳: `CONTRIBUTING.md`, `AGENTS.md`, commitlint 설정(`commitlint.config.*`, `.commitlintrc*`), `.gitmessage`, `git config commit.template`.
- 컨벤션이 없으면 기본값: 영어로 작성하고 Conventional Commits(`feat:`, `fix:`, ...)를 준수한다.
- 제목은 깔끔한 한 줄. 본문은 필요할 때만, 영어 개조식으로 간결하게.
- 쓰기 전에 그 저장소의 기존 메시지를 본다
  (`git --no-pager log --format='%h %s%n%b' -10`).
  불릿 대소문자, 본문 유무, 산문이냐 개조식이냐는 저장소마다 이미 답이 나와 있다.

### 히스토리

- 아직 푸시되지 않은 커밋을 수정할 때는 새 커밋을 쌓지 않고 해당 커밋에 amend/fixup으로 합친다.

### PR

- PR 본문을 쓰기 전에 저장소의 PR 템플릿을 찾고, 있으면 그 구조(섹션·체크리스트)에 맞춰 채운다.
  - 찾을 곳: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, 루트·`docs/`의 `pull_request_template.md` (대소문자 무관).
  - 제목 형식은 저장소 컨벤션(`CONTRIBUTING.md`, 기존 PR 제목 `gh pr list --state merged -L 10`)을 따른다.
- PR을 올리기 전에 제목과 본문을 나에게 먼저 보여주고 검토를 받는다 — 저장소와 상관없이 항상.
  - 승인받은 제목·본문 그대로 `gh pr create --title ... --body ...`로 올린다. `--fill`로 자동 생성하지 않는다.
