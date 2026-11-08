"""Merge repo Claude Code settings into the machine settings file.

usage: merge_settings.py <machine.json> <repo.json> <snapshot.json>

- dicts merge recursively; for scalars the repo value wins
- lists: repo items, plus machine-only items (ones the last applied repo
  snapshot never had); items dropped from the repo are removed
- keys dropped from the repo since the last snapshot are removed;
  machine-local keys (plugins, hooks, model, ...) are kept
- without a snapshot (first run) repo lists win and no keys are removed
- the snapshot is the repo file as last applied
"""

import json
import os
import shutil
import sys
import tempfile

NO_HISTORY = object()


def merge(machine, repo, prev):
    # prev is NO_HISTORY only when there is no snapshot at all; a key the
    # snapshot lacks counts as previously empty.
    history = prev is not NO_HISTORY
    if isinstance(repo, dict) and isinstance(machine, dict):
        prev = prev if isinstance(prev, dict) else {}
        out = {
            k: v
            for k, v in machine.items()
            if not (history and k in prev and k not in repo)
        }
        for k, v in repo.items():
            if k in machine:
                out[k] = merge(machine[k], v, prev.get(k) if history else NO_HISTORY)
            else:
                out[k] = v
        return out
    if isinstance(repo, list) and isinstance(machine, list):
        if not history:
            return repo
        prev = prev if isinstance(prev, list) else []
        return repo + [x for x in machine if x not in repo and x not in prev]
    return repo


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json(path, data):
    # Write through symlinks and keep the existing file mode.
    path = os.path.realpath(path)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    if os.path.exists(path):
        shutil.copymode(path, tmp)
    os.replace(tmp, path)


def main(machine_path, repo_path, snapshot_path):
    repo = load(repo_path)
    prev = load(snapshot_path) if os.path.exists(snapshot_path) else NO_HISTORY
    write_json(machine_path, merge(load(machine_path), repo, prev))
    write_json(snapshot_path, repo)


if __name__ == "__main__":
    main(*sys.argv[1:4])
