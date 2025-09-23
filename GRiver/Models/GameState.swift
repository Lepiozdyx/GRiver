import Foundation

// MARK: - Game Status Enum
enum GameStatus: String, Codable {
    case playing = "playing"
    case victory = "victory"
    case defeat = "defeat"
    case paused = "paused"
    
    var displayName: String {
        switch self {
        case .playing: return "In Progress"
        case .victory: return "Victory"
        case .defeat: return "Defeat"
        case .paused: return "Paused"
        }
    }
}

// MARK: - Game Statistics
struct GameStatistics: Codable {
    var operationsPerformed: Int
    var successfulOperations: Int
    var failedOperations: Int
    var totalResourcesGained: Resource
    var totalResourcesLost: Resource
    var poisCaptured: Int
    var poisDestroyed: Int
    var turnsPlayed: Int
    var gameStartTime: Date
    
    init() {
        self.operationsPerformed = 0
        self.successfulOperations = 0
        self.failedOperations = 0
        self.totalResourcesGained = Resource.zero
        self.totalResourcesLost = Resource.zero
        self.poisCaptured = 0
        self.poisDestroyed = 0
        self.turnsPlayed = 0
        self.gameStartTime = Date()
    }
    
    var successRate: Double {
        guard operationsPerformed > 0 else { return 0.0 }
        return Double(successfulOperations) / Double(operationsPerformed)
    }
    
    var totalPlayTime: TimeInterval {
        return Date().timeIntervalSince(gameStartTime)
    }
    
    mutating func recordOperation(type: ActionType, success: Bool, resourcesGained: Resource, resourcesLost: Resource) {
        operationsPerformed += 1
        if success {
            successfulOperations += 1
            totalResourcesGained += resourcesGained
        } else {
            failedOperations += 1
        }
        totalResourcesLost += resourcesLost
        turnsPlayed += 1
    }
    
    mutating func recordCapture() {
        poisCaptured += 1
    }
    
    mutating func recordDestruction() {
        poisDestroyed += 1
    }
}

// MARK: - Main Game State
struct GameState: Codable {
    var resources: Resource
    var alertLevel: Double // 0.0 to 1.0
    var pointsOfInterest: [PointOfInterest]
    var status: GameStatus
    var statistics: GameStatistics
    var gameID: UUID
    var lastSaveDate: Date
    
    // MARK: - Initialization
    init(pois: [PointOfInterest] = []) {
        self.resources = Resource.startingResources
        self.alertLevel = 0.0
        self.pointsOfInterest = pois.isEmpty ? GameState.generateDefaultPOIs() : pois
        self.status = .playing
        self.statistics = GameStatistics()
        self.gameID = UUID()
        self.lastSaveDate = Date()
    }
    
    // MARK: - Game Progress Properties
    var totalPOIs: Int {
        return pointsOfInterest.count
    }
    
    var activePOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isOperational }
    }
    
    var capturedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isCaptured }
    }
    
    var destroyedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isDestroyed }
    }
    
    var completionPercentage: Double {
        let nonActivePOIs = capturedPOIs.count + destroyedPOIs.count
        guard totalPOIs > 0 else { return 0.0 }
        return Double(nonActivePOIs) / Double(totalPOIs)
    }
    
    // MARK: - Victory/Defeat Conditions
    var isVictory: Bool {
        return activePOIs.isEmpty && status == .playing
    }
    
    var isDefeat: Bool {
        return status == .defeat
    }
    
    var alertPercentage: Int {
        return Int(alertLevel * 100)
    }
    
    // MARK: - Resource Management
    var canAffordAnyOperation: Bool {
        return ActionType.allCases.contains { actionType in
            resources.canAfford(actionType.baseCost) && resources.units >= actionType.minimumUnitsRequired
        }
    }
    
    var totalResourceValue: Int {
        return resources.totalValue
    }
    
    // MARK: - State Mutation Methods
    mutating func increaseAlert(by amount: Double) {
        alertLevel = min(1.0, alertLevel + amount)
        updateGameStatus()
    }
    
    mutating func addResources(_ newResources: Resource) {
        resources += newResources
    }
    
    mutating func spendResources(_ cost: Resource) -> Bool {
        guard resources.canAfford(cost) else { return false }
        resources -= cost
        return true
    }
    
    mutating func updatePOI(at index: Int, with updatedPOI: PointOfInterest) {
        guard index < pointsOfInterest.count else { return }
        pointsOfInterest[index] = updatedPOI
        updateGameStatus()
    }
    
    mutating func findAndUpdatePOI(with id: UUID, updater: (inout PointOfInterest) -> Void) {
        if let index = pointsOfInterest.firstIndex(where: { $0.id == id }) {
            updater(&pointsOfInterest[index])
            updateGameStatus()
        }
    }
    
    mutating func applyGlobalDefenseBonus(_ bonus: Double) {
        let bonusPoints = Int(bonus * 100) // Convert percentage to points
        for index in pointsOfInterest.indices {
            if pointsOfInterest[index].isOperational {
                pointsOfInterest[index].applyDefenseBonus(bonusPoints)
            }
        }
    }
    
    mutating func reduceGlobalEnemyForces(_ reduction: Double) {
        let reductionAmount = Int(reduction * 10) // Convert percentage to unit reduction
        for index in pointsOfInterest.indices {
            if pointsOfInterest[index].isOperational {
                pointsOfInterest[index].reduceUnits(reductionAmount)
            }
        }
    }
    
    mutating func recordOperationResult(_ result: OperationResult) {
        statistics.recordOperation(
            type: result.actionType,
            success: result.success,
            resourcesGained: result.resourcesGained,
            resourcesLost: result.resourcesLost
        )
        
        if result.success {
            switch result.actionType {
            case .capture:
                statistics.recordCapture()
            case .destruction:
                statistics.recordDestruction()
            default:
                break
            }
        }
    }
    
    mutating func triggerDefeat(reason: String = "Base discovered") {
        status = .defeat
        lastSaveDate = Date()
    }
    
    private mutating func updateGameStatus() {
        if isVictory {
            status = .victory
        }
        lastSaveDate = Date()
    }
    
    mutating func resetGame() {
        self = GameState()
    }
    
    // MARK: - Game State Queries
    func poi(withID id: UUID) -> PointOfInterest? {
        return pointsOfInterest.first { $0.id == id }
    }
    
    func poi(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return pointsOfInterest.poi(at: position, tolerance: tolerance)
    }
    
    func canPerformAction(_ action: ActionType, on poi: PointOfInterest) -> ActionValidation {
        return ActionValidator.canPerform(action, with: resources, against: poi)
    }
    
    // MARK: - Default POI Generation
    static func generateDefaultPOIs() -> [PointOfInterest] {
        return [
            PointOfInterest(type: .base, position: CGPoint(x: 200, y: 700)),
            PointOfInterest(type: .base, position: CGPoint(x: 450, y: 400)),
            PointOfInterest(type: .village, position: CGPoint(x: 700, y: 600)),
            PointOfInterest(type: .village, position: CGPoint(x: 300, y: 100)),
            PointOfInterest(type: .village, position: CGPoint(x: 650, y: 450)),
            PointOfInterest(type: .warehouse, position: CGPoint(x: 300, y: 600)),
            PointOfInterest(type: .warehouse, position: CGPoint(x: 650, y: 200)),
            PointOfInterest(type: .station, position: CGPoint(x: 500, y: 650)),
            PointOfInterest(type: .station, position: CGPoint(x: 150, y: 350)),
            PointOfInterest(type: .factory, position: CGPoint(x: 350, y: 380)),
            PointOfInterest(type: .factory, position: CGPoint(x: 750, y: 400))
        ]
    }
}
