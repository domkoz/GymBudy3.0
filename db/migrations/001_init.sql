-- SQLite schema from README

-- Users & settings
CREATE TABLE user_settings (
  id TEXT PRIMARY KEY,
  name TEXT,
  unit_system TEXT CHECK(unit_system IN ('metric','imperial')),
  default_rest_seconds INTEGER DEFAULT 90,
  show_welcome_daily INTEGER DEFAULT 1,
  last_welcome_date TEXT
);

-- Exercise library (definitions)
CREATE TABLE exercise_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  equipment_type TEXT NOT NULL,
  is_bodyweight INTEGER NOT NULL DEFAULT 0,
  bar_weight REAL,
  available_plates TEXT,          -- JSON array per-side (metric/imperial)
  machine_increment REAL,
  dumbbell_steps TEXT             -- JSON array of allowed weights
);

-- Per-user progression state
CREATE TABLE exercise_progression_state (
  id TEXT PRIMARY KEY,
  exercise_definition_id TEXT NOT NULL,
  current_weight REAL NOT NULL,
  current_rep_target INTEGER NOT NULL,
  sets INTEGER NOT NULL,
  starting_reps INTEGER NOT NULL,
  max_reps INTEGER NOT NULL,
  weight_increment_percent REAL NOT NULL,
  min_weight_increment REAL NOT NULL,
  preferred_plate_increment REAL NOT NULL,
  auto_increment INTEGER NOT NULL DEFAULT 1,
  last_used_weight REAL,
  last_used_reps INTEGER,
  personal_record_e1rm REAL,
  consecutive_stalls INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id)
);

CREATE INDEX idx_eps_exercise ON exercise_progression_state(exercise_definition_id);

-- Progression history
CREATE TABLE progression_events (
  id TEXT PRIMARY KEY,
  exercise_definition_id TEXT NOT NULL,
  date TEXT NOT NULL,
  type TEXT CHECK(type IN ('none','repIncrease','weightIncrease')) NOT NULL,
  old_value REAL,
  new_value REAL,
  note TEXT,
  FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id)
);

CREATE INDEX idx_progression_events_exercise_date
ON progression_events(exercise_definition_id, date);

-- Templates
CREATE TABLE templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  estimated_duration_min INTEGER,
  frequency INTEGER,
  last_used TEXT,
  is_favorite INTEGER DEFAULT 0
);

CREATE TABLE template_exercises (
  template_id TEXT,
  exercise_definition_id TEXT,
  sort_order INTEGER,
  sets_override INTEGER,
  PRIMARY KEY(template_id, exercise_definition_id),
  FOREIGN KEY(template_id) REFERENCES templates(id),
  FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id)
);

CREATE INDEX idx_template_exercises_order
ON template_exercises(template_id, sort_order);

-- Workouts
CREATE TABLE workouts (
  id TEXT PRIMARY KEY,
  template_id TEXT,
  template_name TEXT,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  personal_notes TEXT,
  total_volume REAL,
  perceived_exertion INTEGER,
  unit_system TEXT CHECK(unit_system IN ('metric','imperial')),
  FOREIGN KEY(template_id) REFERENCES templates(id)
);

CREATE INDEX idx_workouts_date ON workouts(date);

CREATE TABLE workout_exercises (
  id TEXT PRIMARY KEY,
  workout_id TEXT NOT NULL,
  exercise_definition_id TEXT,
  name TEXT NOT NULL,
  notes TEXT,
  FOREIGN KEY(workout_id) REFERENCES workouts(id),
  FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id)
);

CREATE TABLE workout_sets (
  id TEXT PRIMARY KEY,
  workout_exercise_id TEXT NOT NULL,
  set_index INTEGER NOT NULL,
  target_reps INTEGER NOT NULL,
  target_weight REAL NOT NULL,
  status TEXT CHECK(status IN ('pending','inProgress','completed','failed','skipped','warmup')) NOT NULL,
  actual_reps INTEGER,
  actual_weight REAL,
  is_warmup INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(workout_exercise_id) REFERENCES workout_exercises(id)
);
