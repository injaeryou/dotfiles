---
name: project-audit
description: 프로젝트 정기 점검 — 의존성 취약점·deprecated, 코드 보안, 로컬 환경, CI/CD workflow warning을 검토하고 .docs/audit.md에 기록한다. 월 1회 점검을 승인받았거나 "보안 점검", "정기 점검", "프로젝트 audit" 요청 시 사용. 단일 명령(npm audit 등)만 요청받으면 쓰지 않는다.
---

# 프로젝트 정기 점검

## 1. 이전 기록 확인

- `.docs/audit.md`를 읽는다.
- 이전에 정한 항목은 다시 제안하지 않는다. 예외만 알린다.
  - `[보류]`: 적어 둔 재검토 조건이 충족됐을 때.
  - `[무시]`: 상태가 바뀌었을 때 (새 버전, 심각도 상승).

## 2. 점검

해당 프로젝트에 있는 것만 본다.

- 의존성: 알려진 취약점, deprecated·EOL 패키지와 런타임.
  - 그 생태계 도구를 쓴다 (Python: `uvx pip-audit`, `uv pip list --outdated` / Node: `npm audit`, `npm outdated` 등).
- 코드: 하드코딩된 시크릿, 인젝션, 안전하지 않은 API 사용.
- 로컬 환경: 추적되는 `.env`·키 파일, `.gitignore` 누락, 과한 파일 권한.
- CI/CD: workflow의 warning·deprecated (구버전 action, `set-output` 등), 버전 미고정 action, 과한 `permissions`, 시크릿 노출.
- 빌드·테스트 실행 시 나오는 warning·deprecation 메시지.

## 3. 보고 → 수정

- 발견 항목을 심각도순으로 보고한다. 각 항목에 근거(명령 출력, 파일:줄)를 단다.
- 무엇을 고칠지 내가 고른 뒤에만 수정한다.

## 4. 기록

- 점검을 마치면 수정 여부와 상관없이 `.docs/audit.md` 맨 위에 새 회차를 추가한다 — 맨 위 날짜가 마지막 점검일이다.
  - `.docs/`가 없으면 `.docs/.gitignore`(내용 `*`)부터 만든다.
- 형식:

```markdown
## YYYY-MM-DD

- 범위: 의존성, 코드, 로컬, CI/CD
- [수정함] 항목 — 조치 내용
- [보류] 항목 — 사유, 재검토 조건
- [무시] 항목 — 사유
```
