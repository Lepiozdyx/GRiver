import Foundation

// MARK: - Game State Manager
class GameStateManager {
    private(set) var gameState: GameState
    private let mapManager: MapManager
    
    // MARK: - Initialization
    init() {
        self.gameState = GameState()
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
    }
    
    init(savedGameState: GameState) {
        self.gameState = savedGameState
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
    }
    
    // MARK: - Game State Access
    var currentResources: Resource {
        return gameState.resources
    }
    
    var currentAlertLevel: Double {
        return gameState.alertLevel
    }
    
    var currentStatus: GameStatus {
        return gameState.status
    }
    
    var pointsOfInterest: [PointOfInterest] {
        return gameState.pointsOfInterest
    }
    
    // MARK: - Resource Management
    func addResources(_ resources: Resource) {
        gameState.addResources(resources)
    }
    
    func spendResources(_ cost: Resource) -> Bool {
        return gameState.spendResources(cost)
    }
    
    // MARK: - Alert Level Management
    func increaseAlert(by amount: Double) {
        gameState.increaseAlert(by: amount)
        
        // Check for defeat condition - base discovered
        if gameState.alertLevel >= 1.0 {
            gameState.triggerDefeat(reason: "Base discovered")
        }
    }
    
    // MARK: - POI Operations
    func executeOperation(actionType: ActionType, targetPOI: PointOfInterest) -> OperationResult {
        let result = CombatCalculator.executeOperation(
            actionType: actionType,
            playerResources: gameState.resources,
            targetPOI: targetPOI
        )
        
        // Apply resource changes
        gameState.resources -= result.resourcesLost
        if result.success {
            gameState.resources += result.resourcesGained
        }
        
        // Apply alert level changes
        let alertIncrease = result.success ? actionType.alertIncrease : actionType.failureAlertIncrease
        increaseAlert(by: alertIncrease)
        
        // Update POI state based on action and outcome
        updatePOIAfterOperation(actionType: actionType, targetPOI: targetPOI, success: result.success)
        
        // Apply global consequences
        mapManager.processOperationConsequences(actionType: actionType, success: result.success)
        
        // Update game state POI list with changes from map manager
        gameState.pointsOfInterest = mapManager.exportPOIs()
        
        // Record operation in statistics
        gameState.statistics.recordOperation(
            type: actionType,
            success: result.success,
            resourcesGained: result.resourcesGained,
            resourcesLost: result.resourcesLost
        )
        
        return result
    }
    
    private func updatePOIAfterOperation(actionType: ActionType, targetPOI: PointOfInterest, success: Bool) {
        guard success else { return }
        
        switch actionType {
        case .capture:
            if mapManager.capturePOI(with: targetPOI.id) {
                gameState.statistics.recordCapture()
            }
        case .destruction:
            if mapManager.destroyPOI(with: targetPOI.id) {
                gameState.statistics.recordDestruction()
            }
        case .raid, .robbery:
            // These actions don't change POI status, only weaken them
            break
        }
    }
    
    // MARK: - Base Management
    func upgradeBuilding(_ buildingType: BuildingType, playerBase: inout PlayerBase) -> Bool {
        return EconomyManager.processBaseUpgrade(
            buildingType: buildingType,
            playerBase: &playerBase,
            playerResources: &gameState.resources
        )
    }
    
    func recruitUnits(_ count: Int) -> Bool {
        return EconomyManager.processUnitRecruitment(
            count: count,
            playerResources: &gameState.resources
        )
    }
    
    func purchaseSupplies(ammo: Int = 0, food: Int = 0) -> Bool {
        return EconomyManager.processSupplyPurchase(
            ammo: ammo,
            food: food,
            playerResources: &gameState.resources
        )
    }
    
    // MARK: - Game Status Checks
    var isGameActive: Bool {
        return gameState.status == .playing
    }
    
    var isVictory: Bool {
        return gameState.isVictory
    }
    
    var isDefeat: Bool {
        return gameState.isDefeat
    }
    
    func checkWinCondition() {
        if mapManager.allPOIsCapturedOrDestroyed && gameState.status == .playing {
            gameState.status = .victory
        }
    }
    
    // MARK: - Game Control
    func resetGame() {
        gameState.resetGame()
        mapManager.resetMap()
    }
    
    func pauseGame() {
        if gameState.status == .playing {
            gameState.status = .paused
        }
    }
    
    func resumeGame() {
        if gameState.status == .paused {
            gameState.status = .playing
        }
    }
    
    // MARK: - Save/Load Support
    func exportGameState() -> GameState {
        // Sync POI state from map manager
        gameState.pointsOfInterest = mapManager.exportPOIs()
        gameState.lastSaveDate = Date()
        return gameState
    }
    
    func importGameState(_ newGameState: GameState) {
        gameState = newGameState
        mapManager.importPOIs(newGameState.pointsOfInterest)
    }
    
    // MARK: - Action Validation
    func canPerformAction(_ actionType: ActionType, on poi: PointOfInterest) -> ActionValidation {
        return ActionValidator.canPerform(actionType, with: gameState.resources, against: poi)
    }
    
    func getPOI(withID id: UUID) -> PointOfInterest? {
        return mapManager.poi(withID: id)
    }
    
    func getPOI(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return mapManager.poi(at: position, tolerance: tolerance)
    }
}
