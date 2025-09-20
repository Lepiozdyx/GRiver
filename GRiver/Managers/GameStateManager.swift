import Foundation

class GameStateManager {
    private(set) var gameState: GameState
    private let mapManager: MapManager
    private let baseManager: BaseManager
    
    init() {
        self.gameState = GameState()
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
        self.baseManager = BaseManager()
    }
    
    init(savedGameState: GameState) {
        self.gameState = savedGameState
        self.mapManager = MapManager(pois: gameState.pointsOfInterest)
        self.baseManager = BaseManager()
    }
    
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
    
    func addResources(_ resources: Resource) {
        let validatedResources = baseManager.validateResourceLimits(gameState.resources + resources)
        gameState.resources = validatedResources
    }
    
    func spendResources(_ cost: Resource) -> Bool {
        guard gameState.resources.canAfford(cost) else { return false }
        gameState.resources -= cost
        return true
    }
    
    func increaseAlert(by amount: Double) {
        gameState.increaseAlert(by: amount)
        
        if gameState.alertLevel >= 1.0 {
            gameState.triggerDefeat(reason: "Base discovered")
        }
    }
    
    func upgradeBuilding(_ buildingType: BuildingType) -> Bool {
        let cost = baseManager.getUpgradeCost(for: buildingType)
        guard spendResources(cost) else { return false }
        
        var tempResources = gameState.resources
        let success = baseManager.upgradeBuilding(buildingType, with: &tempResources)
        
        if success {
            return true
        } else {
            addResources(cost)
            return false
        }
    }
    
    func recruitUnits(_ count: Int) -> Bool {
        guard count > 0 else { return false }
        
        guard baseManager.canRecruitUnits(count, currentUnits: gameState.resources.units) else {
            return false
        }
        
        let cost = baseManager.getUnitRecruitmentCost(count)
        
        guard spendResources(cost) else { return false }
        
        gameState.resources.addValue(count, for: .units)
        
        gameState.resources = baseManager.validateResourceLimits(gameState.resources)
        
        return true
    }
    
    func purchaseSupplies(ammo: Int = 0, food: Int = 0) -> Bool {
        guard ammo > 0 || food > 0 else { return false }
        
        guard baseManager.canStoreSupplies(ammo: ammo, food: food, currentResources: gameState.resources) else {
            return false
        }
        
        let cost = baseManager.getSupplyCost(ammo: ammo, food: food)
        
        guard spendResources(cost) else { return false }
        
        gameState.resources.addValue(ammo, for: .ammo)
        gameState.resources.addValue(food, for: .food)
        
        gameState.resources = baseManager.validateResourceLimits(gameState.resources)
        
        return true
    }
    
    func getBaseManager() -> BaseManager {
        return baseManager
    }
    
    func getStorageCapacity() -> Resource {
        return baseManager.storageCapacity
    }
    
    func getMaxUnits() -> Int {
        return baseManager.maxUnits
    }
    
    func executeOperation(actionType: ActionType, targetPOI: PointOfInterest) -> OperationResult {
        let result = CombatCalculator.executeOperation(
            actionType: actionType,
            playerResources: gameState.resources,
            targetPOI: targetPOI
        )
        
        gameState.resources -= result.resourcesLost
        if result.success {
            let gainedResources = baseManager.validateResourceLimits(gameState.resources + result.resourcesGained)
            gameState.resources = gainedResources
        }
        
        let alertIncrease = result.success ? actionType.alertIncrease : actionType.failureAlertIncrease
        increaseAlert(by: alertIncrease)
        
        updatePOIAfterOperation(actionType: actionType, targetPOI: targetPOI, success: result.success)
        
        mapManager.processOperationConsequences(actionType: actionType, success: result.success)
        
        gameState.pointsOfInterest = mapManager.exportPOIs()
        
        gameState.statistics.recordOperation(
            type: actionType,
            success: result.success,
            resourcesGained: result.resourcesGained,
            resourcesLost: result.resourcesLost
        )
        
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
            break
        }
    }
    
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
    
    func exportGameState() -> GameState {
        gameState.pointsOfInterest = mapManager.exportPOIs()
        gameState.lastSaveDate = Date()
        return gameState
    }
    
    func importGameState(_ newGameState: GameState) {
        gameState = newGameState
        mapManager.importPOIs(newGameState.pointsOfInterest)
    }
    
    func canPerformAction(_ actionType: ActionType, on poi: PointOfInterest) -> ActionValidation {
        return ActionValidator.canPerform(actionType, with: gameState.resources, against: poi)
    }
    
    func getPOI(withID id: UUID) -> PointOfInterest? {
        return mapManager.poi(withID: id)
    }
    
    func getPOI(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return mapManager.poi(at: position, tolerance: tolerance)
    }
    
    func validateResources(_ resources: Resource) -> Resource {
        return baseManager.validateResourceLimits(resources)
    }
    
    func canAffordOperation(_ actionType: ActionType) -> Bool {
        return gameState.resources.canAfford(actionType.baseCost)
    }
    
    func canUpgradeBuilding(_ buildingType: BuildingType) -> Bool {
        let cost = baseManager.getUpgradeCost(for: buildingType)
        
        guard gameState.resources.canAfford(cost) else { return false }
        
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
    
    func getMapStatistics() -> MapStatistics {
        return mapManager.getMapStatistics()
    }
    
    func getBaseValidation() -> BaseValidation {
        return baseManager.validateBaseOperations(resources: gameState.resources)
    }
    
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
