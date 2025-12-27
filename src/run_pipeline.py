from __future__ import annotations

import hashlib
import json
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def utc_now_iso() -> str:
    """Return current UTC time as an ISO-8601 string (no microseconds)"""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def sha256_file(path: Path) -> str:
    """Hash a file to show which config produced which run"""
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def read_git_commit() -> str | None:
    """If git is available, capture the exact commit hash for auditability"""
    import subprocess

    try:
        out = subprocess.check_output(["git", "rev-parse", "HEAD"], stderr=subprocess.DEVNULL)
        return out.decode().strip()
    except Exception:
        return None


def init_db(db_path: Path, schema_path: Path) -> None:
    """Create/initialize the SQLite DB and apply schema.sql"""
    db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(db_path) as conn:
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.executescript(schema_path.read_text(encoding="utf-8"))
        conn.commit()


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python src/run_pipeline.py config/base.yaml", file=sys.stderr)
        return 2

    config_path = Path(sys.argv[1]).resolve()
    repo_root = Path(__file__).resolve().parents[1]

    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))

    outputs_dir = repo_root / cfg["paths"]["outputs_dir"]
    db_path = repo_root / cfg["paths"]["db_path"]
    schema_path = repo_root / "sql" / "schema.sql"

    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "_" + cfg["project"]["run_tag"]
    run_dir = outputs_dir / f"run_{run_id}"
    run_dir.mkdir(parents=True, exist_ok=False)

    meta = {
        "run_id": run_id,
        "started_at": utc_now_iso(),
        "git_commit": read_git_commit(),
        "config_path": str(config_path),
        "config_sha256": sha256_file(config_path),
        "python_executable": sys.executable,
        "cwd": os.getcwd(),
    }

    (run_dir / "run_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    (run_dir / "config_snapshot.yaml").write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")

    init_db(db_path=db_path, schema_path=schema_path)

    print(f"OK: created run folder: {run_dir}")
    print(f"OK: initialized db: {db_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
