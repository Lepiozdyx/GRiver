import Foundation

// MARK: - Action Type Enum
enum ActionType: String, CaseIterable, Codable {
    case raid = "raid"
    case robbery = "robbery"
    case capture = "capture"
    case destruction = "destruction"
    
    // MARK: - Display Properties
    var displayName: String {
        switch self {
        case .raid: return "Raid"
        case .robbery: return "Robbery"
        case .capture: return "Capture"
        case .destruction: return "Destruction"
        }
    }
    
    var description: String {
        switch self {
        case .raid: return "Quick strike to gather resources and weaken defenses"
        case .robbery: return "Steal supplies with moderate risk"
        case .capture: return "Take control of the location permanently" 
        case .destruction: return "Destroy the target and reduce enemy forces"
        }
    }
    
    var icon: String {
        switch self {
        case .raid: return "⚡"
        case .robbery: return "💰"
        case .capture: return "🏴"
        case .destruction: return "💥"
        }
    }
    
    // MARK: - Combat Properties
    var successCoefficient: Double {
        switch self {
        case .raid: return 1.5
        case .robbery: return 0.8
        case .capture: return 0.5
        case .destruction: return 1.0
        }
    }
    
    var baseCost: Resource {
        switch self {
        case .raid: return Resource.raidCost
        case .robbery: return Resource.robberyCost
        case .capture: return Resource.captureCost
        case .destruction: return Resource.destructionCost
        }
    }
    
    var minimumUnitsRequired: Int {
        switch self {
        case .raid: return 1
        case .robbery: return 2
        case .capture: return 3
        case .destruction: return 2
        }
    }
    
    // MARK: - Outcome Effects
    var alertIncrease: Double {
        switch self {
        case .raid: return 0.10
        case .robbery: return 0.10
        case .capture: return 0.0 // No direct alert increase
        case .destruction: return 0.10
        }
    }
    
    var defenseBonus: Double {
        switch self {
        case .raid: return 0.05
        case .robbery: return 0.05
        case .capture: return 0.10
        case .destruction: return 0.0 // No defense bonus, reduces enemy forces instead
        }
    }
    
    var enemyForceReduction: Double {
        switch self {
        case .raid: return 0.0
        case .robbery: return 0.0
        case .capture: return 0.0
        case .destruction: return 0.10
        }
    }
    
    // MARK: - Success Rewards
    func successReward(for poi: PointOfInterest) -> Resource {
        switch self {
        case .raid: return poi.raidReward
        case .robbery: return poi.robberyReward
        case .capture: return poi.captureReward
        case .destruction: return poi.destructionReward
        }
    }
    
    var baseSuccessReward: Resource {
        switch self {
        case .raid: return Resource(money: 100, ammo: 5, food: 5, units: 5)
        case .robbery: return Resource(money: 150, ammo: 10, food: 10, units: 5)
        case .capture: return Resource(money: 300, ammo: 15, food: 15, units: 10)
        case .destruction: return Resource(money: 50, ammo: 1, food: 1, units: 1)
        }
    }
    
    // MARK: - Risk Assessment
    var riskLevel: RiskLevel {
        switch self {
        case .raid: return .medium
        case .robbery: return .high
        case .capture: return .veryHigh
        case .destruction: return .medium
        }
    }
    
    var isDestructive: Bool {
        switch self {
        case .raid: return false
        case .robbery: return false
        case .capture: return false
        case .destruction: return true
        }
    }
    
    var isPermanent: Bool {
        switch self {
        case .raid: return false
        case .robbery: return false
        case .capture: return true
        case .destruction: return true
        }
    }
    
    // MARK: - Strategic Properties
    var priority: Int {
        switch self {
        case .raid: return 3
        case .robbery: return 2
        case .capture: return 4
        case .destruction: return 1
        }
    }
    
    var recommendedForPOITypes: [POIType] {
        switch self {
        case .raid: return [.village, .warehouse, .station]
        case .robbery: return [.warehouse, .factory]
        case .capture: return [.base, .factory, .station]
        case .destruction: return [.base] // Most effective against heavily defended targets
        }
    }
    
    // MARK: - Failure Consequences
    var failurePenalty: Resource {
        let basePenalty = Resource.failurePenalty
        switch self {
        case .raid: return basePenalty
        case .robbery: return basePenalty * 1.2
        case .capture: return basePenalty * 2.0
        case .destruction: return basePenalty * 1.5
        }
    }
    
    var failureAlertIncrease: Double {
        return alertIncrease * 1.5 // Failed operations cause more alarm
    }
}

// MARK: - Risk Level Enum
enum RiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
    case veryHigh = "veryHigh"
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .veryHigh: return "Very High Risk"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }
}

// MARK: - Action Validation
struct ActionValidator {
    static func canPerform(_ action: ActionType, with resources: Resource, against poi: PointOfInterest) -> ActionValidation {
        var issues: [String] = []
        
        // Check if POI is valid target
        if !poi.isOperational {
            issues.append("Target is not operational")
        }
        
        // Check resource requirements
        if !resources.canAfford(action.baseCost) {
            issues.append("Insufficient resources")
        }
        
        // Check minimum units
        if resources.units < action.minimumUnitsRequired {
            issues.append("Need at least \(action.minimumUnitsRequired) units")
        }
        
        // Check if action makes strategic sense
        if action == .capture && poi.isCaptured {
            issues.append("Target already captured")
        }
        
        if action == .destruction && poi.isDestroyed {
            issues.append("Target already destroyed")
        }
        
        return ActionValidation(isValid: issues.isEmpty, issues: issues)
    }
}

// MARK: - Action Validation Result
struct ActionValidation {
    let isValid: Bool
    let issues: [String]
    
    var errorMessage: String {
        return issues.joined(separator: ", ")
    }
}
