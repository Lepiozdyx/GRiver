import Foundation

// MARK: - Combat Calculator
class CombatCalculator {
    
    // MARK: - Core Combat Calculations
    
    /// Calculate player combat strength according to TS formula:
    /// strength = units + (ammo * 0.5) + (food * 0.2)
    static func calculatePlayerStrength(resources: Resource) -> Double {
        return Double(resources.units) + (Double(resources.ammo) * 0.5) + (Double(resources.food) * 0.2)
    }
    
    /// Calculate enemy combat strength according to TS formula:
    /// strength = base defense + unit count
    static func calculateEnemyStrength(poi: PointOfInterest) -> Double {
        return Double(poi.totalDefense + poi.currentUnits)
    }
    
    /// Calculate success probability according to TS formula:
    /// P(success) = (Player Strength / Enemy Strength) × Action Coefficient
    static func calculateSuccessProbability(
        playerStrength: Double,
        enemyStrength: Double,
        actionType: ActionType
    ) -> Double {
        guard enemyStrength > 0 else { return 1.0 }
        
        let baseRatio = playerStrength / enemyStrength
        let probability = baseRatio * actionType.successCoefficient
        
        // Cap probability between 0.05 and 0.95 for gameplay balance
        return max(0.05, min(0.95, probability))
    }
    
    /// Determine operation outcome according to TS rule:
    /// If P < 0.5 → failure, otherwise → success
    static func determineOutcome(successProbability: Double) -> OperationOutcome {
        return successProbability >= 0.5 ? .success : .failure
    }
    
    // MARK: - Complete Combat Resolution
    
    static func executeOperation(
        actionType: ActionType,
        playerResources: Resource,
        targetPOI: PointOfInterest
    ) -> OperationResult {
        
        let playerStrength = calculatePlayerStrength(resources: playerResources)
        let enemyStrength = calculateEnemyStrength(poi: targetPOI)
        let successProbability = calculateSuccessProbability(
            playerStrength: playerStrength,
            enemyStrength: enemyStrength,
            actionType: actionType
        )
        
        let outcome = determineOutcome(successProbability: successProbability)
        
        let resourcesLost = calculateResourcesLost(
            actionType: actionType,
            outcome: outcome,
            playerResources: playerResources
        )
        
        let resourcesGained = calculateResourcesGained(
            actionType: actionType,
            outcome: outcome,
            targetPOI: targetPOI
        )
        
        return OperationResult(
            actionType: actionType,
            targetPOI: targetPOI,
            outcome: outcome,
            resourcesLost: resourcesLost,
            resourcesGained: resourcesGained,
            playerStrength: playerStrength,
            enemyStrength: enemyStrength,
            successProbability: successProbability
        )
    }
    
    // MARK: - Resource Calculations
    
    private static func calculateResourcesLost(
        actionType: ActionType,
        outcome: OperationOutcome,
        playerResources: Resource
    ) -> Resource {
        
        var totalLoss = actionType.baseCost
        
        // Add failure penalty if operation failed
        if outcome == .failure {
            totalLoss += actionType.failurePenalty
        }
        
        return totalLoss
    }
    
    private static func calculateResourcesGained(
        actionType: ActionType,
        outcome: OperationOutcome,
        targetPOI: PointOfInterest
    ) -> Resource {
        
        guard outcome == .success else {
            return Resource.zero
        }
        
        // Return rewards according to TS specifications
        switch actionType {
        case .raid:
            return Resource(money: 0, ammo: 5, food: 5, units: 5)
        case .robbery:
            return Resource(money: 0, ammo: 10, food: 10, units: 5)
        case .capture:
            return Resource(money: 0, ammo: 15, food: 15, units: 10)
        case .destruction:
            return Resource(money: 0, ammo: 1, food: 1, units: 1)
        }
    }
    
    // MARK: - Pre-Operation Analysis
    
    static func analyzeOperation(
        actionType: ActionType,
        playerResources: Resource,
        targetPOI: PointOfInterest
    ) -> OperationAnalysis {
        
        let validation = ActionValidator.canPerform(actionType, with: playerResources, against: targetPOI)
        
        guard validation.isValid else {
            return OperationAnalysis(
                isViable: false,
                successProbability: 0.0,
                expectedLoss: Resource.zero,
                expectedGain: Resource.zero,
                riskAssessment: "Operation not viable: \(validation.errorMessage)",
                recommendation: "Address issues before attempting operation"
            )
        }
        
        let playerStrength = calculatePlayerStrength(resources: playerResources)
        let enemyStrength = calculateEnemyStrength(poi: targetPOI)
        let successProbability = calculateSuccessProbability(
            playerStrength: playerStrength,
            enemyStrength: enemyStrength,
            actionType: actionType
        )
        
        let expectedLoss = calculateExpectedLoss(actionType: actionType, successProbability: successProbability)
        let expectedGain = calculateExpectedGain(actionType: actionType, successProbability: successProbability, targetPOI: targetPOI)
        
        let riskAssessment = generateRiskAssessment(
            successProbability: successProbability,
            playerStrength: playerStrength,
            enemyStrength: enemyStrength
        )
        
        let recommendation = generateRecommendation(
            actionType: actionType,
            successProbability: successProbability,
            targetPOI: targetPOI
        )
        
        return OperationAnalysis(
            isViable: true,
            successProbability: successProbability,
            expectedLoss: expectedLoss,
            expectedGain: expectedGain,
            riskAssessment: riskAssessment,
            recommendation: recommendation
        )
    }
    
    private static func calculateExpectedLoss(actionType: ActionType, successProbability: Double) -> Resource {
        let baseLoss = actionType.baseCost
        let failurePenalty = actionType.failurePenalty
        let failureProbability = 1.0 - successProbability
        
        // Expected loss = base cost + (failure probability × failure penalty)
        let expectedFailureLoss = failurePenalty * failureProbability
        return baseLoss + expectedFailureLoss
    }
    
    private static func calculateExpectedGain(actionType: ActionType, successProbability: Double, targetPOI: PointOfInterest) -> Resource {
        let potentialGain = calculateResourcesGained(actionType: actionType, outcome: .success, targetPOI: targetPOI)
        return potentialGain * successProbability
    }
    
    private static func generateRiskAssessment(successProbability: Double, playerStrength: Double, enemyStrength: Double) -> String {
        let probabilityPercent = Int(successProbability * 100)
        
        if successProbability >= 0.8 {
            return "Low risk (\(probabilityPercent)%) - Your forces significantly outmatch the enemy"
        } else if successProbability >= 0.6 {
            return "Medium risk (\(probabilityPercent)%) - Favorable odds but some uncertainty"
        } else if successProbability >= 0.4 {
            return "High risk (\(probabilityPercent)%) - Challenging operation with significant danger"
        } else {
            return "Very high risk (\(probabilityPercent)%) - Enemy forces are superior, high chance of failure"
        }
    }
    
    private static func generateRecommendation(actionType: ActionType, successProbability: Double, targetPOI: PointOfInterest) -> String {
        if successProbability >= 0.7 {
            return "Recommended - Good chance of success with acceptable risk"
        } else if successProbability >= 0.5 {
            return "Consider carefully - Moderate risk, ensure you can afford losses"
        } else if successProbability >= 0.3 {
            return "High risk - Consider reinforcing or choosing different target"
        } else {
            return "Not recommended - Find easier target or strengthen your forces"
        }
    }
    
    // MARK: - Comparative Analysis
    
    static func compareActionTypes(
        playerResources: Resource,
        targetPOI: PointOfInterest
    ) -> [ActionType: OperationAnalysis] {
        
        var comparisons: [ActionType: OperationAnalysis] = [:]
        
        for actionType in ActionType.allCases {
            comparisons[actionType] = analyzeOperation(
                actionType: actionType,
                playerResources: playerResources,
                targetPOI: targetPOI
            )
        }
        
        return comparisons
    }
    
    static func getBestActionType(
        playerResources: Resource,
        targetPOI: PointOfInterest
    ) -> ActionType? {
        
        let comparisons = compareActionTypes(playerResources: playerResources, targetPOI: targetPOI)
        let viableActions = comparisons.filter { $0.value.isViable && $0.value.successProbability >= 0.3 }
        
        return viableActions.max { first, second in
            // Prioritize higher success probability, then higher expected value
            if abs(first.value.successProbability - second.value.successProbability) < 0.1 {
                let firstValue = first.value.expectedGain.totalValue - first.value.expectedLoss.totalValue
                let secondValue = second.value.expectedGain.totalValue - second.value.expectedLoss.totalValue
                return firstValue < secondValue
            } else {
                return first.value.successProbability < second.value.successProbability
            }
        }?.key
    }
}

// MARK: - Operation Analysis Structure
struct OperationAnalysis {
    let isViable: Bool
    let successProbability: Double
    let expectedLoss: Resource
    let expectedGain: Resource
    let riskAssessment: String
    let recommendation: String
    
    var successPercentage: Int {
        return Int(successProbability * 100)
    }
    
    var expectedNetValue: Int {
        return expectedGain.totalValue - expectedLoss.totalValue
    }
    
    var isWorthwhile: Bool {
        return isViable && successProbability >= 0.3 && expectedNetValue > 0
    }
}
