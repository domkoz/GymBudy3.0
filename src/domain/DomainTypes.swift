// Domain Types (from README)

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
