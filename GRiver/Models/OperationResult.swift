import Foundation

// MARK: - Operation Outcome
enum OperationOutcome: String, Codable {
    case success = "success"
    case failure = "failure"
    
    var displayName: String {
        switch self {
        case .success: return "Success"
        case .failure: return "Failure"
        }
    }
    
    var isSuccess: Bool {
        return self == .success
    }
}

// MARK: - Operation Result Model
struct OperationResult: Codable {
    var id = UUID()
    let actionType: ActionType
    let targetPOI: PointOfInterest
    let outcome: OperationOutcome
    let resourcesLost: Resource
    let resourcesGained: Resource
    let timestamp: Date
    let playerStrength: Double
    let enemyStrength: Double
    let successProbability: Double
    
    // MARK: - Initialization
    init(
        actionType: ActionType,
        targetPOI: PointOfInterest,
        outcome: OperationOutcome,
        resourcesLost: Resource,
        resourcesGained: Resource,
        playerStrength: Double,
        enemyStrength: Double,
        successProbability: Double
    ) {
        self.actionType = actionType
        self.targetPOI = targetPOI
        self.outcome = outcome
        self.resourcesLost = resourcesLost
        self.resourcesGained = resourcesGained
        self.timestamp = Date()
        self.playerStrength = playerStrength
        self.enemyStrength = enemyStrength
        self.successProbability = successProbability
    }
    
    // MARK: - Computed Properties
    var success: Bool {
        return outcome.isSuccess
    }
    
    var netResourceChange: Resource {
        return resourcesGained - resourcesLost
    }
    
    var wasWorthwhile: Bool {
        return success && (netResourceChange.totalValue > 0)
    }
    
    var totalLoss: Int {
        return resourcesLost.totalValue
    }
    
    var totalGain: Int {
        return resourcesGained.totalValue
    }
    
    var netValue: Int {
        return totalGain - totalLoss
    }
    
    var successPercentage: Int {
        return Int(successProbability * 100)
    }
    
    // MARK: - Display Properties
    var outcomeMessage: String {
        switch outcome {
        case .success:
            switch actionType {
            case .raid: return "Raid completed successfully"
            case .robbery: return "Robbery executed successfully" 
            case .capture: return "Target captured"
            case .destruction: return "Target destroyed"
            }
        case .failure:
            switch actionType {
            case .raid: return "Raid failed"
            case .robbery: return "Robbery failed"
            case .capture: return "Capture attempt failed"
            case .destruction: return "Destruction attempt failed"
            }
        }
    }
    
    var detailMessage: String {
        let probabilityPercent = Int(successProbability * 100)
        let strengthRatio = playerStrength / enemyStrength
        
        if success {
            return "Operation succeeded with \(probabilityPercent)% chance. Your forces proved superior."
        } else {
            return "Operation failed despite \(probabilityPercent)% chance. Enemy defenses held strong."
        }
    }
    
    var impactSummary: String {
        if success && !resourcesGained.isEmpty {
            var summary = "Gained: "
            var gains: [String] = []
            
            if resourcesGained.money > 0 { gains.append("\(resourcesGained.money) money") }
            if resourcesGained.ammo > 0 { gains.append("\(resourcesGained.ammo) ammo") }
            if resourcesGained.food > 0 { gains.append("\(resourcesGained.food) food") }
            if resourcesGained.units > 0 { gains.append("\(resourcesGained.units) units") }
            
            summary += gains.joined(separator: ", ")
            return summary
        } else if !resourcesLost.isEmpty {
            var summary = "Lost: "
            var losses: [String] = []
            
            if resourcesLost.money > 0 { losses.append("\(resourcesLost.money) money") }
            if resourcesLost.ammo > 0 { losses.append("\(resourcesLost.ammo) ammo") }
            if resourcesLost.food > 0 { losses.append("\(resourcesLost.food) food") }
            if resourcesLost.units > 0 { losses.append("\(resourcesLost.units) units") }
            
            summary += losses.joined(separator: ", ")
            return summary
        }
        
        return "No resources changed"
    }
    
    // MARK: - Risk Assessment
    var riskLevel: RiskLevel {
        if successProbability >= 0.8 {
            return .low
        } else if successProbability >= 0.6 {
            return .medium
        } else if successProbability >= 0.4 {
            return .high
        } else {
            return .veryHigh
        }
    }
    
    var wasHighRisk: Bool {
        return successProbability < 0.5
    }
    
    var wasLowReward: Bool {
        return resourcesGained.totalValue < 100
    }
    
    // MARK: - Strategic Analysis
    var recommendedFollowUp: String {
        if success {
            switch actionType {
            case .raid, .robbery:
                return "Consider capturing this weakened target"
            case .capture:
                return "Defend captured position and expand operations"
            case .destruction:
                return "Reduced enemy presence - opportunity for expansion"
            }
        } else {
            return "Consider reinforcing before attempting similar operations"
        }
    }
    
    var experienceBonusMessage: String? {
        if success && wasHighRisk {
            return "High-risk operation succeeded - tactical experience gained"
        }
        return nil
    }
    
    // MARK: - POI Impact
    var poiStatusChange: String {
        switch actionType {
        case .capture:
            return success ? "POI captured and under your control" : "POI remains under enemy control"
        case .destruction:
            return success ? "POI destroyed and removed from map" : "POI damaged but still operational"
        case .raid, .robbery:
            return success ? "POI weakened but still operational" : "POI defenses reinforced after failed attack"
        }
    }
    
    // MARK: - Alert Level Impact
    func alertImpact() -> String {
        let alertIncrease = success ? actionType.alertIncrease : actionType.failureAlertIncrease
        let percentage = Int(alertIncrease * 100)
        
        if percentage > 0 {
            return "Enemy alert level increased by \(percentage)%"
        } else {
            return "No change to enemy alert level"
        }
    }
}

// MARK: - Operation History
struct OperationHistory: Codable {
    private var operations: [OperationResult] = []
    
    var count: Int {
        return operations.count
    }
    
    var isEmpty: Bool {
        return operations.isEmpty
    }
    
    var recentOperations: [OperationResult] {
        return Array(operations.suffix(10))
    }
    
    var successfulOperations: [OperationResult] {
        return operations.filter { $0.success }
    }
    
    var failedOperations: [OperationResult] {
        return operations.filter { !$0.success }
    }
    
    mutating func addOperation(_ result: OperationResult) {
        operations.append(result)
        
        // Keep only last 50 operations to manage memory
        if operations.count > 50 {
            operations.removeFirst()
        }
    }
    
    func operationsBy(actionType: ActionType) -> [OperationResult] {
        return operations.filter { $0.actionType == actionType }
    }
    
    func operationsAgainst(poiType: POIType) -> [OperationResult] {
        return operations.filter { $0.targetPOI.type == poiType }
    }
    
    var successRate: Double {
        guard !operations.isEmpty else { return 0.0 }
        let successful = operations.filter { $0.success }.count
        return Double(successful) / Double(operations.count)
    }
}
