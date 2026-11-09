## Python

- 환경·의존성·실행은 항상 `uv`를 사용한다 (`uv add`, `uv run`, ...).
- 린트/포맷은 `ruff`.

### 테스트 (`pytest`)

- 테스트는 `pytest`로 작성하고 `uv run pytest`로 실행한다.
- `tests/` 폴더는 소스 코드와 1:1로 같은 폴더 구조를 유지한다 (예: `src/pkg/mod.py` → `tests/pkg/test_mod.py`).
- 테스트 파일은 `test_*.py`, 테스트 함수는 `test_*`로 명명한다.
