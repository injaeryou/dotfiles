import importlib.util
import json
from pathlib import Path

import pytest

_spec = importlib.util.spec_from_file_location(
    "merge_settings", Path(__file__).parents[2] / "scripts" / "merge_settings.py"
)
ms = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ms)


def test_list_keeps_machine_only_and_drops_removed_repo_items():
    machine = {"permissions": {"allow": ["a", "old", "local"]}}
    prev = {"permissions": {"allow": ["a", "old"]}}
    repo = {"permissions": {"allow": ["a", "new"]}}
    assert ms.merge(machine, repo, prev) == {
        "permissions": {"allow": ["a", "new", "local"]}
    }


def test_item_moved_between_lists_leaves_old_list():
    machine = {"permissions": {"allow": [], "ask": ["x"]}}
    prev = {"permissions": {"allow": [], "ask": ["x"]}}
    repo = {"permissions": {"allow": ["x"], "ask": []}}
    assert ms.merge(machine, repo, prev) == {"permissions": {"allow": ["x"], "ask": []}}


def test_without_snapshot_repo_lists_win_and_keys_are_kept():
    machine = {"permissions": {"ask": ["stale"]}, "model": "opus"}
    repo = {"permissions": {"ask": ["a"]}}
    assert ms.merge(machine, repo, ms.NO_HISTORY) == {
        "permissions": {"ask": ["a"]},
        "model": "opus",
    }


def test_key_dropped_from_repo_is_removed_but_local_key_kept():
    machine = {"gone": 1, "hooks": {"h": 1}, "keep": 2}
    prev = {"gone": 1, "keep": 1}
    repo = {"keep": 3}
    assert ms.merge(machine, repo, prev) == {"hooks": {"h": 1}, "keep": 3}


def test_main_writes_merge_and_snapshot(tmp_path):
    machine, repo, snap = tmp_path / "m.json", tmp_path / "r.json", tmp_path / "s.json"
    machine.write_text(json.dumps({"model": "opus", "permissions": {"allow": ["old"]}}))
    repo.write_text(json.dumps({"permissions": {"allow": ["new"]}}))

    ms.main(machine, repo, snap)

    assert json.loads(machine.read_text()) == {
        "model": "opus",
        "permissions": {"allow": ["new"]},
    }
    assert json.loads(snap.read_text()) == {"permissions": {"allow": ["new"]}}


def test_invalid_machine_json_fails_and_leaves_file_untouched(tmp_path):
    machine, repo, snap = tmp_path / "m.json", tmp_path / "r.json", tmp_path / "s.json"
    machine.write_text("{broken")
    repo.write_text("{}")

    with pytest.raises(json.JSONDecodeError):
        ms.main(machine, repo, snap)

    assert machine.read_text() == "{broken"
    assert not snap.exists()


def test_key_missing_from_snapshot_keeps_machine_only_items():
    machine = {"permissions": {"allow": ["A", "LOCAL"]}}
    repo = {"permissions": {"allow": ["A"]}}
    assert ms.merge(machine, repo, {}) == {"permissions": {"allow": ["A", "LOCAL"]}}


def test_write_keeps_mode_and_symlink(tmp_path):
    real = tmp_path / "real.json"
    real.write_text("{}")
    real.chmod(0o644)
    link = tmp_path / "link.json"
    link.symlink_to(real)

    ms.write_json(str(link), {"a": 1})

    assert link.is_symlink()
    assert json.loads(real.read_text()) == {"a": 1}
    assert real.stat().st_mode & 0o777 == 0o644
