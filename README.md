# GymBuddy — Product Specification (v1.0)

Minimalist personal workout companion to reduce cognitive load, track meaningful progress, and remember intelligently.

## Table of Contents
- [Overview](#overview)
- [Objectives & Success Metrics](#objectives--success-metrics)
- [Core User Experience Flows](#core-user-experience-flows)
- [Detailed Screen Specifications](#detailed-screen-specifications)
- [Data Model](#data-model)
- [Progression System (Authoritative)](#progression-system-authoritative)
- [UI/UX Implications](#uiux-implications)
- [Acceptance Criteria (Progression)](#acceptance-criteria-progression)
- [Smart Features](#smart-features)
- [Empty States & Onboarding](#empty-states--onboarding)
- [Testing Strategy](#testing-strategy)
- [Accessibility & Internationalization](#accessibility--internationalization)
- [Settings](#settings)
- [Notifications](#notifications)
- [Analytics & Telemetry](#analytics--telemetry)
- [Non-Functional Requirements](#non-functional-requirements)
- [API & Sync (Future)](#api--sync-future)
- [Data Export](#data-export)
- [Security & Privacy](#security--privacy)
- [Release Plan & Feature Flags](#release-plan--feature-flags)
- [Content Management](#content-management)
- [Error Handling](#error-handling)
- [Glossary](#glossary)
- [Example Configurations](#example-configurations)
- [Example Acceptance Tests (succinct)](#example-acceptance-tests-succinct)

---

## Overview

- **Vision**: Minimalist personal workout companion to reduce cognitive load, track meaningful progress, and remember intelligently.
- **Core Principles**: Minimalist design; Personal use first; Smart memory; Flow-state focus.
- **Target Users**: Primary—You; Secondary—your girlfriend; both intermediate/advanced.
- **Platforms**: Mobile-first. Offline-first local storage with optional sync later.
- **Units**: Metric (kg) or Imperial (lb), user-configurable with consistent rounding.

## Objectives & Success Metrics

- **Engagement**: ≥3 workouts logged/week.
- **Usability**: Start → Complete workout in ≤5 taps (common path).
- **Satisfaction**: Zero confusing moments in “Start, Log Sets, Complete.”
- **Retention**: ≥30-day continuous usage.
- **Additional KPIs**: “Quick Start” adoption ≥60%, “Auto Progression” acceptance ≥70%, <3% overrides due to bad suggestions.

## Core User Experience Flows

- **Primary Flow: Start Workout**
  - App Launch → Main → Start Training → Choose Template → Active Workout → Complete → Save & Review
  - Date defaults to today; changing date is available but not required.

- **Alternative Flows**
  - **Quick Start**: Main → “Start Today’s Workout” (1 tap; predicted template).
  - **Plan**: Calendar → Long-press date → Schedule Workout.
  - **Review**: Calendar → Tap completed date → Summary & History.

## Detailed Screen Specifications

- **Welcome (Daily)**
  - Content: “Hi [Name]!”, rotating motivational quote, brand mark.
  - Behavior: Shows first app launch per day, 2 seconds; skippable on tap.

- **Main Dashboard (Home)**
  - Header: Today’s date; dynamic greeting.
  - Quick Actions:
    - Start Workout (primary): Uses today + predicted template.
    - Quick Continue: Visible if a session is in progress.
    - Weekly Overview: Planned vs Done; progress bar.
    - Today’s Schedule: Next planned template + top 3 exercises.
  - Context-Aware:
    - After 7pm with no workout → “Keep the streak alive?”
    - In-progress workout → sticky “Resume” banner.

- **Training Selection**
  - Sections: Recent (top 3), Favorites, All Templates, [ + Create New ].
  - Interactions: Tap to select; tap-hold to preview; search/filter.
  - Empty State: “No templates. Create your first workout in 2 minutes.”

- **Active Workout**
  - Modes:
    - Focus Mode (default): Current exercise, sets editor, big controls.
    - Analytics Mode (expand): Today/Last/Best/Trend; PR badges.
  - Exercise Card:
    - Name; working sets with weight/reps editors and status.
    - Next exercise peek; swipe re-order or skip.
    - Controls: +/- weight, +/- reps, Set Complete.
    - Rest timer: Auto-start on set completion; adjustable.
  - Smart Helpers:
    - Auto-suggest next set target (progression + history).
    - Struggle action (appears after a below-target set): “-2.5 kg”.
    - PR detection: Subtle haptic + badge.
    - Notes Layer: Per-exercise notes on a separate sheet.
  - Accessibility: Large tap targets; dynamic type; optional haptics.

- **Global Navigation**
  - Today (Home), Plan (Calendar), Progress (Analytics), Library (Templates & Exercises).

- **Completion & Review**
  - Completion Screen: Duration, total volume, RPE (1–10), achievements, progression updates.
  - Review: Workout summary; set details; notes; export/share.

## Data Model

### Domain Types (App Layer)

```swift
enum UnitSystem { case metric, imperial }

enum ProgressionType { case repIncrease, weightIncrease, none }

enum SetStatus { case pending, inProgress, completed, failed, skipped, warmup }

enum EquipmentType { case barbell, dumbbell, machine, cable, bodyweight, kettlebell, band }

struct SetTarget {
    var targetReps: Int
    var targetWeight: Double // display units
    var status: SetStatus
    var actualReps: Int?
    var actualWeight: Double?
    var isWarmup: Bool
}

// Library entity: shared across templates
struct ExerciseDefinition {
    let id: UUID
    var name: String
    var category: String
    var equipmentType: EquipmentType
    var isBodyweight: Bool
    // Equipment context
    var barWeight: Double? // e.g., 20kg bar; nil for non-barbell
    var availablePlates: [Double]? // per-side plate sizes, e.g., [25, 20, 15, 10, 5, 2.5, 1.25]
    var machineIncrement: Double? // e.g., 2.5 kg; for machines/cables
    var dumbbellSteps: [Double]? // allowed dumbbells, e.g., [2.5, 5, 7.5, ...]
}

// Per-user, per-exercise progression state
struct ExerciseProgressionState {
    let id: UUID
    let exerciseDefinitionId: UUID
    // Baseline prescription
    var currentWeight: Double
    var currentRepTarget: Int
    var sets: Int
    // Progression configuration
    var startingReps: Int // default 8
    var maxReps: Int      // default 12
    var weightIncrementPercent: Double // default 5.0
    var minWeightIncrement: Double     // 2.5 kg / 5 lb
    var preferredPlateIncrement: Double // 1.25 kg / 2.5 lb
    var autoIncrement: Bool // suggestions auto-applied if true
    // Analytics and memory
    var lastUsedWeight: Double
    var lastUsedReps: Int
    var personalRecordE1RM: Double
    var consecutiveStalls: Int // for deload suggestion
}

struct ProgressionEvent {
    let id: UUID
    var date: Date
    var exerciseDefinitionId: UUID
    var type: ProgressionType
    var oldValue: Double
    var newValue: Double
    var note: String?
}

struct TemplateExercise {
    let templateId: UUID
    let exerciseDefinitionId: UUID
    var sortOrder: Int
    // Optional per-template overrides
    var setsOverride: Int?
}

struct TrainingTemplate {
    let id: UUID
    var name: String
    var exercises: [TemplateExercise]
    var category: String
    var estimatedDurationMin: Int
    var frequency: Int
    var lastUsed: Date?
    var isFavorite: Bool
}

struct LoggedExercise {
    let id: UUID
    let exerciseDefinitionId: UUID
    var name: String
    var setTargets: [SetTarget]
    var notes: String?
}

struct CompletedTraining {
    let id: UUID
    var templateId: UUID?
    var templateName: String
    var date: Date
    var exercises: [LoggedExercise]
    var personalNotes: String?
    var startTime: Date
    var endTime: Date
    var totalVolume: Double
    var perceivedExertion: Int // 1–10
    var achievements: [String] // labels (PRs, streaks)
    var unitSystem: UnitSystem
}
```

### Local Database Schema (SQLite)

```sql
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
  type TEXT CHECK(type IN ('repIncrease','weightIncrease')) NOT NULL,
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
```

## Progression System (Authoritative)

### Definitions
- **Working set**: A set contributing to progression evaluation; excludes sets marked warmup, drop, rest-pause, or cluster.
- **Achieved**: actualReps ≥ threshold (target or max).
- **Stall**: Session outcome “maintain” with at least one failed or below-target working set.

### Progression Logic Rules (with precedence)
- IF (all working sets for the exercise achieved MAX reps)
  - THEN increase weight by 2.5–5% (configurable), round to equipment-achievable weight, and reset reps to startingReps next session
- ELSE IF (all working sets achieved current rep target AND current target < maxReps)
  - THEN increase rep target by +1 next session (same weight)
- ELSE
  - maintain current weight and rep target next session

Scope: Evaluated per exercise, not across the entire workout.

Exclusions: Warm-up sets do not affect progression outcome.

### Algorithm (pseudocode)

```text
function nextPrescription(exerciseState, setResults, unitSystem, equipment):
  working = [s for s in setResults where s.status == completed and s.isWarmup == false]
  if working.isEmpty:
      return { nextWeight: exerciseState.currentWeight,
               nextReps: exerciseState.currentRepTarget,
               type: none }

  allAtLeastTarget = all(s.actualReps >= exerciseState.currentRepTarget for s in working)
  allAtLeastMax = all(s.actualReps >= exerciseState.maxReps for s in working)

  if allAtLeastMax:
      raw = exerciseState.currentWeight * (1 + exerciseState.weightIncrementPercent / 100.0)
      nextWeight = roundToEquipment(raw, equipment, exerciseState)
      return { nextWeight, nextReps: exerciseState.startingReps, type: weightIncrease }

  if allAtLeastTarget and exerciseState.currentRepTarget < exerciseState.maxReps:
      return { nextWeight: exerciseState.currentWeight,
               nextReps: exerciseState.currentRepTarget + 1,
               type: repIncrease }

  return { nextWeight: exerciseState.currentWeight,
           nextReps: exerciseState.currentRepTarget,
           type: none }

function roundToEquipment(targetWeight, equipment, exerciseState):
  if equipment.type == barbell:
      -- v1 heuristic: round to nearest multiple of exerciseState.minWeightIncrement
      rounded = round(targetWeight / exerciseState.minWeightIncrement) * exerciseState.minWeightIncrement
      return max(rounded, exerciseState.currentWeight)  -- never reduce unless deload
  if equipment.type == dumbbell:
      -- pick nearest allowed dumbbell pair or single from equipment.dumbbellSteps
      return nearestAllowed(targetWeight, equipment.dumbbellSteps, tieBreakUp=true)
  if equipment.type in {machine, cable}:
      -- round to machine increment
      inc = equipment.machineIncrement or exerciseState.minWeightIncrement
      rounded = round(targetWeight / inc) * inc
      return max(rounded, exerciseState.currentWeight)
  if equipment.type == bodyweight:
      return exerciseState.currentWeight  -- no weight progression
  return targetWeight
```

- **Policy**: Tie-break upward. Never propose less than current unless a deload is applied.
- **Unit switching**: Convert all stored baselines to new units and re-round to equipment-achievable increments; record a `ProgressionEvent` with note “unit conversion.”

### PR Detection
- **Estimated 1RM (Epley)**: \(\text{e1RM} = \text{weight} \times (1 + \text{reps}/30)\)
- **PR types**: Weight PR (for a rep range), Rep PR (at/above baseline weight), Estimated 1RM PR.
- **Threshold**: e1RM PR if > personalRecordE1RM by ≥1%, with 3% hysteresis to reduce churn.

### Edge Cases
- Any failed/skipped working set prevents progression for that exercise.
- Warm-ups excluded from evaluation.
- AMRAP sets: Count toward PRs; for progression either:
  - Use all working sets excluding AMRAP to evaluate; or
  - If only AMRAP exists, treat as single working set.
- Bodyweight-only: Rep-only progression; when at max, maintain max or suggest tempo/time.
- Repeated stalls: After ≥2 consecutive stalls, display deload suggestion: reduce by minWeightIncrement (or -5%) and reset reps to startingReps (non-destructive suggestion).

### Configuration (Per Exercise)
- startingReps default 8; maxReps default 12.
- weightIncrementPercent default 5.0 (big lifts may use 2.5).
- minWeightIncrement default 2.5 kg / 5 lb; preferredPlateIncrement default 1.25 kg / 2.5 lb.
- autoIncrement toggle to auto-apply suggestions.

## UI/UX Implications
- Active Workout banner: “2 more reps across sets until weight increase” when close to max.
- Post-Workout “Progression Updates”: per-exercise bullets (rep +1 / weight ↑ and reps reset / maintain).
- Next Session: Prefill targets from `nextPrescription`; allow inline manual override.

## Acceptance Criteria (Progression)
- **Priority**: If all working sets reach max reps, weight increase overrides rep increase even when target condition is true.
- **Rep progression**: Given 3×8@60kg all completed (each ≥8, not all ≥12) → next 3×9@60kg.
- **Weight progression**: Given 3×12@60kg all completed → next 3×8@rounded(60×1.05), rounded per equipment and unit, never below 60.
- **Maintain**: Any working set < target reps or any failed/skipped → next remains currentWeight/currentRepTarget.
- **Warm-ups**: Sets flagged warmup do not affect progression, volume, or PRs.
- **Manual override**: Overrides set the new baseline immediately; subsequent progression applies from that baseline.
- **Stall/deload**: After two consecutive stalls with at least one failed/below-target working set per session → show deload suggestion.
- **Rounding**: Proposed next weight is always achievable by the equipment in the current unit system.

## Smart Features

### Template Prediction (v1 heuristic)
- **Inputs**: weekday usage pattern, recency, favorite flag, category rotation.
- **Rule**: If a template used this weekday ≥3 of last 4 weeks → predict it; else most recent favorite; else top Recent.
- **Target**: ≥70% match after 4 weeks.

### Recovery Awareness (info-only in v1)
- **Signals**: rolling weekly volume, days trained, average RPE.
- **Nudge**: If ≥4 consecutive days trained with avg RPE ≥8 → suggest rest/active recovery.

### Minimalist Interactions
- Swipe exercise for options; tap-hold for history; haptic confirmations; voice notes (future).

## Empty States & Onboarding
- **First Launch**: Name; 2) Goal selection (Strength/Muscle/Fitness); Create first template with common exercises; 4) Quick tutorial.
- **Empty States**: “Ready for your first workout?”; “Build your first template”; “Your progress will appear here.”

## Testing Strategy

### Unit Tests
- Progression: target vs max precedence; warm-up exclusion; failure paths; manual override.
- Rounding: barbell/machine/dumbbell across kg/lb; tie-break upward.
- PR detection: thresholds and hysteresis.

### Integration Tests
- Start→Log→Complete pipeline; next session prefill reflects progression.
- Template prediction accuracy with seeded history.

### E2E Tests
- Quick Start to completion in ≤5 taps on populated account.
- Override persists; next session uses overridden baseline.

### Property-Based
- For random sets arrays, `nextPrescription` always yields reps ∈ [startingReps, maxReps].

## Accessibility & Internationalization
- Dynamic type; high-contrast theme; haptics optional.
- Units localized; number formatting per locale; RTL-ready.

## Settings
- Units (kg/lb), default rest timer (30–240s).
- Progression defaults with per-exercise overrides.
- Behavior: Auto-apply suggestions, haptics, daily welcome.
- Data: Export JSON/CSV; clear local data with confirmation.

## Notifications
- Rest timer local notification on timer end.
- Daily reminder (configurable); suppressed after completion.
- Optional post-workout progression summary.

## Analytics & Telemetry
- **Events**: app_opened, workout_started/resumed/completed, set_completed/failed, progression_suggested/applied/overridden, pr_detected, template_predicted/overridden.
- **Privacy-first**: toggle to disable analytics; no PII; anonymized IDs.

## Non-Functional Requirements
- Offline-first; crash-safe writes; versioned schema migrations.
- Performance: UI <16ms/frame; progression computation <50ms for 30 sets.
- Battery: OS timers for rest; minimal background work.
- Timezone: Use local time for “today” and streaks; store UTC with offset.
- Precision: Store weights as decimals or integer subunits (e.g., grams) to avoid float errors.

## API & Sync (Future)
- v1 local only; later backup/sync:
  - POST /backup (encrypted dataset), GET /restore.
- Conflict: last-write-wins per-entity updated_at; future CRDT.

## Data Export
- JSON (all entities), CSV (workouts, sets, exercises).
- Share sheet; filenames like `gymbudy_export_YYYYMMDD`.

## Security & Privacy
- Local encryption-at-rest where supported; secure key storage.
- No third-party sharing; clear privacy policy; GDPR export/delete.

## Release Plan & Feature Flags
- **v1.0**: Core flows, progression, PR detection, basic prediction, offline storage.
- **Flags**:
  - `auto_apply_progression` (default on)
  - `advanced_plate_math` (off)
  - `recovery_awareness` (off; info-only)
- **v1.1**: Advanced charts, streaks, better prediction.
- **v1.2**: Sync/backup; watch timers.

## Content Management
- Quotes shipped in-app; rotate daily; 14-day no-repeat.
- Exercise categories: Push/Pull/Legs/Core/Cardio/Accessory (editable).

## Error Handling
- Failed writes: local retry with backoff; non-blocking toast on persistent failure.
- Corrupt DB: safe reset flow with export prompt.
- Unit changes mid-workout: prohibited; allowed post-workout with conversion.

## Glossary
- **Working Set**: Set included in progression evaluation (not warmup/drop/rest-pause/cluster).
- **Achieved**: actualReps ≥ threshold (target or max).
- **Stall**: Maintain outcome with at least one failed/below-target working set.
- **Deload Suggestion**: Recommendation to reduce load by min increment or 5% after repeated stalls.

## Example Configurations

```text
// Strength-focused (e.g., deadlift)
startingReps = 5
maxReps = 8
weightIncrementPercent = 2.5
minWeightIncrement = 2.5  // kg
preferredPlateIncrement = 1.25

// Hypertrophy-focused (e.g., biceps curls)
startingReps = 10
maxReps = 15
weightIncrementPercent = 5.0
minWeightIncrement = 2.5  // kg
preferredPlateIncrement = 1.25
```

## Example Acceptance Tests (succinct)
- 3×8@60kg all completed (none <8; not all ≥12) → next 3×9@60kg.
- 3×12@60kg all completed → next 3×8@63kg (5% rounded by equipment; not <60).
- 3×9 target but a set with 8 reps → maintain 3×9@60kg next session.
- Warm-ups excluded: 2 warmups + 3 working sets (all ≥target) → progression applies.
- Manual override to 3×10@62.5kg → baseline updates; progression resumes from override.
- Two consecutive stalls with below-target sets → show deload suggestion.

---

Rewrote progression precedence and per-exercise scope, defined “achieved,” excluded warm-ups, added equipment-aware rounding, and expanded acceptance criteria.

Consolidated the full spec into a copy-ready document with updated data model and schema.
