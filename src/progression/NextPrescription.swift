import Foundation

struct EquipmentContext {
    var type: EquipmentType
    var dumbbellSteps: [Double]?
    var machineIncrement: Double?
}

struct NextPrescriptionResult {
    var nextWeight: Double
    var nextReps: Int
    var type: ProgressionType
}

func roundToEquipment(targetWeight: Double, equipment: EquipmentContext, state: ExerciseProgressionState) -> Double {
    switch equipment.type {
    case .barbell:
        let inc = state.minWeightIncrement
        let rounded = (targetWeight / inc).rounded() * inc
        return max(rounded, state.currentWeight)
    case .dumbbell:
        guard let steps = equipment.dumbbellSteps, !steps.isEmpty else { return targetWeight }
        var nearest = steps[0]
        var minDiff = abs(targetWeight - nearest)
        for s in steps {
            let d = abs(targetWeight - s)
            if d < minDiff || (abs(d - minDiff) < 1e-9 && s > nearest) {
                nearest = s
                minDiff = d
            }
        }
        return max(nearest, state.currentWeight)
    case .machine, .cable:
        let inc = equipment.machineIncrement ?? state.minWeightIncrement
        let rounded = (targetWeight / inc).rounded() * inc
        return max(rounded, state.currentWeight)
    case .bodyweight, .kettlebell, .band:
        return state.currentWeight
    }
}

func nextPrescription(state: ExerciseProgressionState,
                      setResults: [SetTarget],
                      unitSystem: UnitSystem,
                      equipment: EquipmentContext) -> NextPrescriptionResult {
    let working = setResults.filter { $0.status == .completed && $0.isWarmup == false }
    guard working.isEmpty == false else {
        return NextPrescriptionResult(nextWeight: state.currentWeight,
                                      nextReps: state.currentRepTarget,
                                      type: .none)
    }

    let allAtLeastTarget = working.allSatisfy { (set) in
        guard let reps = set.actualReps else { return false }
        return reps >= state.currentRepTarget
    }
    let allAtLeastMax = working.allSatisfy { (set) in
        guard let reps = set.actualReps else { return false }
        return reps >= state.maxReps
    }

    if allAtLeastMax {
        let raw = state.currentWeight * (1.0 + state.weightIncrementPercent / 100.0)
        let rounded = roundToEquipment(targetWeight: raw, equipment: equipment, state: state)
        return NextPrescriptionResult(nextWeight: rounded,
                                      nextReps: state.startingReps,
                                      type: .weightIncrease)
    }

    if allAtLeastTarget && state.currentRepTarget < state.maxReps {
        return NextPrescriptionResult(nextWeight: state.currentWeight,
                                      nextReps: state.currentRepTarget + 1,
                                      type: .repIncrease)
    }

    return NextPrescriptionResult(nextWeight: state.currentWeight,
                                  nextReps: state.currentRepTarget,
                                  type: .none)
}
