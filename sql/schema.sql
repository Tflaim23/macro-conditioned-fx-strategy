PRAGMA foreign_keys = ON;


CREATE TABLE IF NOT EXISTS backtest_runs (
  run_id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  git_commit TEXT,
  config_path TEXT NOT NULL,
  config_sha256 TEXT NOT NULL,
  tag TEXT
);

CREATE TABLE IF NOT EXISTS run_artifacts (
  artifact_id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id TEXT NOT NULL,
  artifact_type TEXT NOT NULL,
  relative_path TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (run_id) REFERENCES backtest_runs(run_id)
);

CREATE TABLE IF NOT EXISTS prices_fx_spot (
  instrument TEXT NOT NULL,
  ts TEXT NOT NULL,
  price REAL NOT NULL,
  source TEXT,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (instrument, ts)
);

CREATE TABLE IF NOT EXISTS returns_fx_forward_excess (
  instrument TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end TEXT NOT NULL,
  return_excess REAL NOT NULL,
  method TEXT NOT NULL,
  source TEXT,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (instrument, period_start, period_end)
);

CREATE TABLE IF NOT EXISTS rates_short (
  currency TEXT NOT NULL,
  period_date TEXT NOT NULL,
  asof_date TEXT NOT NULL,
  value REAL NOT NULL,
  source TEXT,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (currency, period_date, asof_date)
);

CREATE TABLE IF NOT EXISTS macro_series_raw (
  series_id TEXT NOT NULL,
  period_date TEXT NOT NULL,
  asof_date TEXT NOT NULL,
  value REAL,
  vintage_tag TEXT,
  source TEXT,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (series_id, period_date, asof_date)
);

CREATE TABLE IF NOT EXISTS macro_series_clean (
  series_id TEXT NOT NULL,
  period_date TEXT NOT NULL,
  asof_date TEXT NOT NULL,
  value REAL,
  qc_flag TEXT,
  source TEXT,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (series_id, period_date, asof_date)
);

CREATE TABLE IF NOT EXISTS features_vintage (
  decision_date TEXT NOT NULL,
  instrument TEXT NOT NULL,
  feature_name TEXT NOT NULL,
  feature_value REAL,

  source_table TEXT NOT NULL,
  source_series_id TEXT,
  source_period_date TEXT,
  source_asof_date TEXT,

  inserted_at TEXT NOT NULL,

  PRIMARY KEY (decision_date, instrument, feature_name)
);
