import Foundation
import XCTest

class NextPrescriptionTests: XCTestCase {
    func testRepIncreaseWhenAllAtLeastTarget() {
        let state = ExerciseProgressionState(
            id: UUID(),
            exerciseDefinitionId: UUID(),
            currentWeight: 60,
            currentRepTarget: 8,
            sets: 3,
            startingReps: 8,
            maxReps: 12,
            weightIncrementPercent: 5.0,
            minWeightIncrement: 2.5,
            preferredPlateIncrement: 1.25,
            autoIncrement: true,
            lastUsedWeight: 60,
            lastUsedReps: 8,
            personalRecordE1RM: 0,
            consecutiveStalls: 0
        )

        let sets = [
            SetTarget(targetReps: 8, targetWeight: 60, status: .completed, actualReps: 8, actualWeight: 60, isWarmup: false),
            SetTarget(targetReps: 8, targetWeight: 60, status: .completed, actualReps: 8, actualWeight: 60, isWarmup: false),
            SetTarget(targetReps: 8, targetWeight: 60, status: .completed, actualReps: 8, actualWeight: 60, isWarmup: false)
        ]

        let equipment = EquipmentContext(type: .barbell, dumbbellSteps: nil, machineIncrement: nil)
        let result = nextPrescription(state: state, setResults: sets, unitSystem: .metric, equipment: equipment)

        XCTAssertEqual(result.type, .repIncrease)
        XCTAssertEqual(result.nextReps, 9)
        XCTAssertEqual(result.nextWeight, 60)
    }
}
