import Foundation

// MARK: - Game State Manager
class GameStateManager {
    private(set) var gameState: GameState
    private let mapManager: MapManager
    private let baseManager: BaseManager
    
    // MARK: - Initialization
    init() {
        self.gameState = GameState()
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
        self.baseManager = BaseManager()
    }
    
    init(savedGameState: GameState) {
        self.gameState = savedGameState
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
        
        // Initialize base manager with saved base data if available
        // For now, use default base - in future versions could save/load base state
        self.baseManager = BaseManager()
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
    
    var playerBase: PlayerBase {
        return baseManager.exportBase()
    }
    
    // MARK: - Resource Management
    func addResources(_ resources: Resource) {
        // Validate against storage capacity
        let validatedResources = baseManager.validateResourceLimits(gameState.resources + resources)
        gameState.resources = validatedResources
    }
    
    func spendResources(_ cost: Resource) -> Bool {
        guard gameState.resources.canAfford(cost) else { return false }
        gameState.resources -= cost
        return true
    }
    
    // MARK: - Alert Level Management
    func increaseAlert(by amount: Double) {
        gameState.increaseAlert(by: amount)
        
        // Check for defeat condition - base discovered
        if gameState.alertLevel >= 1.0 {
            gameState.triggerDefeat(reason: "Base discovered")
        }
    }
    
    // MARK: - Base Management
    func upgradeBuilding(_ buildingType: BuildingType) -> Bool {
        let cost = baseManager.getUpgradeCost(for: buildingType)
        guard spendResources(cost) else { return false }
        
        // Upgrade through base manager using general method
        var tempResources = gameState.resources
        let success = baseManager.upgradeBuilding(buildingType, with: &tempResources)
        
        if success {
            // Base upgrade successful, resources already deducted
            return true
        } else {
            // Refund resources if upgrade failed
            addResources(cost)
            return false
        }
    }
    
    func recruitUnits(_ count: Int) -> Bool {
        guard count > 0 else { return false }
        
        // Check if we can recruit this many units
        guard baseManager.canRecruitUnits(count, currentUnits: gameState.resources.units) else {
            return false
        }
        
        // Calculate cost
        let cost = baseManager.getUnitRecruitmentCost(count)
        
        // Check if we can afford it
        guard spendResources(cost) else { return false }
        
        // Add units to resources
        gameState.resources.addValue(count, for: .units)
        
        // Validate against capacity limits
        gameState.resources = baseManager.validateResourceLimits(gameState.resources)
        
        return true
    }
    
    func purchaseSupplies(ammo: Int = 0, food: Int = 0) -> Bool {
        guard ammo > 0 || food > 0 else { return false }
        
        // Check if we can store these supplies
        guard baseManager.canStoreSupplies(ammo: ammo, food: food, currentResources: gameState.resources) else {
            return false
        }
        
        // Calculate cost
        let cost = baseManager.getSupplyCost(ammo: ammo, food: food)
        
        // Check if we can afford it
        guard spendResources(cost) else { return false }
        
        // Add supplies to resources
        gameState.resources.addValue(ammo, for: .ammo)
        gameState.resources.addValue(food, for: .food)
        
        // Validate against capacity limits
        gameState.resources = baseManager.validateResourceLimits(gameState.resources)
        
        return true
    }
    
    // MARK: - Base Access
    func getBaseManager() -> BaseManager {
        return baseManager
    }
    
    func getStorageCapacity() -> Resource {
        return baseManager.storageCapacity
    }
    
    func getMaxUnits() -> Int {
        return baseManager.maxUnits
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
            let gainedResources = baseManager.validateResourceLimits(gameState.resources + result.resourcesGained)
            gameState.resources = gainedResources
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
        
        // Check win condition after successful operations
        checkWinCondition()
        
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
        // Note: BaseManager retains its state - could reset if needed
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
        // Note: Base state is not imported - could be enhanced in future
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
    
    // MARK: - Resource Validation
    func validateResources(_ resources: Resource) -> Resource {
        return baseManager.validateResourceLimits(resources)
    }
    
    func canAffordOperation(_ actionType: ActionType) -> Bool {
        return gameState.resources.canAfford(actionType.baseCost)
    }
    
    // MARK: - Base Operations Validation
    func canUpgradeBuilding(_ buildingType: BuildingType) -> Bool {
        let cost = baseManager.getUpgradeCost(for: buildingType)
        
        // Check if we can afford the upgrade cost
        guard gameState.resources.canAfford(cost) else { return false }
        
        // Check if building is not at max level
        switch buildingType {
        case .storage:
            return baseManager.storageLevel < BuildingType.storage.maxLevel
        case .barracks:
            return baseManager.barracksLevel < BuildingType.barracks.maxLevel
        }
    }
    
    func canRecruitUnits(_ count: Int) -> Bool {
        let cost = baseManager.getUnitRecruitmentCost(count)
        return gameState.resources.canAfford(cost) &&
               baseManager.canRecruitUnits(count, currentUnits: gameState.resources.units)
    }
    
    func canPurchaseSupplies(ammo: Int, food: Int) -> Bool {
        let cost = baseManager.getSupplyCost(ammo: ammo, food: food)
        return gameState.resources.canAfford(cost) &&
               baseManager.canStoreSupplies(ammo: ammo, food: food, currentResources: gameState.resources)
    }
    
    // MARK: - Statistics and Information
    func getMapStatistics() -> MapStatistics {
        return mapManager.getMapStatistics()
    }
    
    func getBaseValidation() -> BaseValidation {
        return baseManager.validateBaseOperations(resources: gameState.resources)
    }
    
    // MARK: - Debug Support
    var debugInfo: String {
        let mapStats = mapManager.getMapStatistics()
        return """
        GameStateManager Debug:
        Status: \(gameState.status.displayName)
        Alert: \(Int(gameState.alertLevel * 100))%
        Resources: \(gameState.resources.totalValue) total value
        POIs: \(mapStats.activePOIs) active, \(mapStats.capturedPOIs) captured, \(mapStats.destroyedPOIs) destroyed
        Base Level: \(baseManager.totalBuildingLevels)
        Storage: \(baseManager.storageLevel), Barracks: \(baseManager.barracksLevel)
        Operations: \(gameState.statistics.operationsPerformed)
        """
    }
}
