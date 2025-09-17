import Foundation

// MARK: - Map Manager
class MapManager {
    private(set) var pointsOfInterest: [PointOfInterest] = []
    
    // MARK: - Initialization
    init(pois: [PointOfInterest] = []) {
        if pois.isEmpty {
            self.pointsOfInterest = GameState.generateDefaultPOIs()
        } else {
            self.pointsOfInterest = pois
        }
    }
    
    // MARK: - POI Access
    var activePOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isOperational }
    }
    
    var capturedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isCaptured }
    }
    
    var destroyedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isDestroyed }
    }
    
    var totalPOIs: Int {
        return pointsOfInterest.count
    }
    
    var completionPercentage: Double {
        let nonActivePOIs = capturedPOIs.count + destroyedPOIs.count
        guard totalPOIs > 0 else { return 0.0 }
        return Double(nonActivePOIs) / Double(totalPOIs)
    }
    
    var allPOIsCapturedOrDestroyed: Bool {
        return activePOIs.isEmpty
    }
    
    // MARK: - POI Search
    func poi(withID id: UUID) -> PointOfInterest? {
        return pointsOfInterest.first { $0.id == id }
    }
    
    func poi(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return pointsOfInterest.first { poi in
            let distance = sqrt(pow(poi.position.x - position.x, 2) + pow(poi.position.y - position.y, 2))
            return distance <= tolerance && poi.isOperational
        }
    }
    
    func poisByType(_ type: POIType) -> [PointOfInterest] {
        return pointsOfInterest.filter { $0.type == type }
    }
    
    func poisByStatus(_ status: POIStatus) -> [PointOfInterest] {
        return pointsOfInterest.filter { $0.status == status }
    }
    
    // MARK: - POI Updates
    func updatePOI(with id: UUID, updater: (inout PointOfInterest) -> Void) {
        if let index = pointsOfInterest.firstIndex(where: { $0.id == id }) {
            updater(&pointsOfInterest[index])
        }
    }
    
    func capturePOI(with id: UUID) -> Bool {
        if let index = pointsOfInterest.firstIndex(where: { $0.id == id && $0.isOperational }) {
            pointsOfInterest[index].capture()
            return true
        }
        return false
    }
    
    func destroyPOI(with id: UUID) -> Bool {
        if let index = pointsOfInterest.firstIndex(where: { $0.id == id && $0.isOperational }) {
            pointsOfInterest[index].destroy()
            return true
        }
        return false
    }
    
    // MARK: - Global Effects Implementation
    func applyGlobalDefenseBonus(_ bonus: Double) {
        let bonusPoints = Int(bonus * 100) // Convert percentage to points
        
        for index in pointsOfInterest.indices {
            if pointsOfInterest[index].isOperational {
                pointsOfInterest[index].applyDefenseBonus(bonusPoints)
            }
        }
    }
    
    func reduceGlobalEnemyForces(_ reduction: Double) {
        let reductionAmount = Int(reduction * 10) // Convert percentage to unit reduction
        
        for index in pointsOfInterest.indices {
            if pointsOfInterest[index].isOperational {
                pointsOfInterest[index].reduceUnits(reductionAmount)
            }
        }
    }
    
    func processOperationConsequences(actionType: ActionType, success: Bool) {
        if success {
            switch actionType {
            case .raid, .robbery:
                // Apply defense bonus to remaining enemy bases
                applyGlobalDefenseBonus(actionType.defenseBonus)
                
            case .capture:
                // Stronger defense bonus for captures
                applyGlobalDefenseBonus(actionType.defenseBonus)
                
            case .destruction:
                // Reduce enemy forces globally
                reduceGlobalEnemyForces(actionType.enemyForceReduction)
            }
        } else {
            // Failed operations also cause defensive reinforcements
            let failureBonus = actionType.defenseBonus * 0.5 // Smaller bonus for failures
            applyGlobalDefenseBonus(failureBonus)
        }
    }
    
    // MARK: - POI Reinforcement
    func reinforcePOI(with id: UUID, additionalUnits: Int) {
        updatePOI(with: id) { poi in
            poi.reinforceUnits(additionalUnits)
        }
    }
    
    func reinforceRandomPOIs(count: Int, unitsPerPOI: Int) {
        let operationalPOIs = activePOIs
        guard !operationalPOIs.isEmpty else { return }
        
        let reinforcementCount = min(count, operationalPOIs.count)
        let selectedPOIs = Array(operationalPOIs.shuffled().prefix(reinforcementCount))
        
        for poi in selectedPOIs {
            reinforcePOI(with: poi.id, additionalUnits: unitsPerPOI)
        }
    }
    
    // MARK: - Map Statistics
    func getMapStatistics() -> MapStatistics {
        return MapStatistics(
            totalPOIs: totalPOIs,
            activePOIs: activePOIs.count,
            capturedPOIs: capturedPOIs.count,
            destroyedPOIs: destroyedPOIs.count,
            completionPercentage: completionPercentage,
            totalEnemyStrength: getTotalEnemyStrength(),
            averageDefenseLevel: getAverageDefenseLevel(),
            poisByType: getPOICountsByType()
        )
    }
    
    private func getTotalEnemyStrength() -> Int {
        return activePOIs.reduce(0) { $0 + $1.totalStrength }
    }
    
    private func getAverageDefenseLevel() -> Double {
        let operationalPOIs = activePOIs
        guard !operationalPOIs.isEmpty else { return 0.0 }
        
        let totalDefense = operationalPOIs.reduce(0) { $0 + $1.totalDefense }
        return Double(totalDefense) / Double(operationalPOIs.count)
    }
    
    private func getPOICountsByType() -> [POIType: Int] {
        var counts: [POIType: Int] = [:]
        
        for type in POIType.allCases {
            counts[type] = pointsOfInterest.filter { $0.type == type }.count
        }
        
        return counts
    }
    
    // MARK: - Validation
    func validateMapState() -> MapValidation {
        var issues: [String] = []
        
        // Check for POIs with negative values
        for poi in pointsOfInterest {
            if poi.currentDefense < 0 {
                issues.append("POI \(poi.type.displayName) has negative defense")
            }
            if poi.currentUnits < 0 {
                issues.append("POI \(poi.type.displayName) has negative units")
            }
        }
        
        // Check for duplicate positions
        let positions = pointsOfInterest.map { $0.position }
        let uniquePositions = Set(positions.map { "\($0.x),\($0.y)" })
        if positions.count != uniquePositions.count {
            issues.append("Duplicate POI positions detected")
        }
        
        return MapValidation(isValid: issues.isEmpty, issues: issues)
    }
    
    // MARK: - Save/Load Support
    func exportPOIs() -> [PointOfInterest] {
        return pointsOfInterest
    }
    
    func importPOIs(_ pois: [PointOfInterest]) {
        pointsOfInterest = pois
    }
    
    // MARK: - Reset
    func resetMap() {
        pointsOfInterest = GameState.generateDefaultPOIs()
    }
}

// MARK: - Map Statistics Structure
struct MapStatistics {
    let totalPOIs: Int
    let activePOIs: Int
    let capturedPOIs: Int
    let destroyedPOIs: Int
    let completionPercentage: Double
    let totalEnemyStrength: Int
    let averageDefenseLevel: Double
    let poisByType: [POIType: Int]
    
    var progressSummary: String {
        return "\(capturedPOIs + destroyedPOIs)/\(totalPOIs) objectives completed"
    }
}

// MARK: - Map Validation
struct MapValidation {
    let isValid: Bool
    let issues: [String]
    
    var errorMessage: String {
        return issues.joined(separator: ", ")
    }
}
