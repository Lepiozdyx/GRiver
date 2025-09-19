import Foundation
import Combine

// MARK: - Base View Model
class BaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var playerResources: Resource = Resource.zero
    @Published var playerBase: PlayerBase = PlayerBase()
    
    // UI State
    @Published var showUpgradeAlert: Bool = false
    @Published var showPurchaseAlert: Bool = false
    @Published var showRecruitmentAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = ""
    
    // Form inputs
    @Published var ammoToBuy: Int = 0
    @Published var foodToBuy: Int = 0
    @Published var unitsToBuy: Int = 1
    
    // MARK: - Managers
    let baseManager: BaseManager
    private let economyManager = EconomyManager.self
    private var gameStateManager: GameStateManager?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Validation States
    @Published var canUpgradeStorage: Bool = false
    @Published var canUpgradeBarracks: Bool = false
    @Published var canAffordUnits: Bool = false
    @Published var canAffordSupplies: Bool = false
    
    // MARK: - Initialization
    init(baseManager: BaseManager = BaseManager()) {
        self.baseManager = baseManager
        self.playerBase = baseManager.exportBase()
        updateValidationStates()
    }
    
    convenience init(gameStateManager: GameStateManager) {
        self.init()
        setGameStateManager(gameStateManager)
    }
    
    // MARK: - GameStateManager Integration
    func setGameStateManager(_ manager: GameStateManager) {
        self.gameStateManager = manager
        refreshData()
    }
    
    // MARK: - Data Refresh
    func refreshData() {
        guard let gameManager = gameStateManager else {
            // Fallback to default state
            playerResources = Resource.startingResources
            playerBase = PlayerBase()
            updateValidationStates()
            return
        }
        
        // Sync resources from game state
        playerResources = gameManager.currentResources
        
        // Note: playerBase is managed locally by baseManager
        // It doesn't need to sync from GameStateManager as the base
        // upgrades are handled through this ViewModel
        playerBase = baseManager.exportBase()
        
        updateValidationStates()
    }
    
    private func updateValidationStates() {
        canUpgradeStorage = baseManager.canUpgradeStorage(with: playerResources)
        canUpgradeBarracks = baseManager.canUpgradeBarracks(with: playerResources)
        
        let unitCost = baseManager.getUnitRecruitmentCost(unitsToBuy)
        canAffordUnits = playerResources.canAfford(unitCost) &&
                        baseManager.canRecruitUnits(unitsToBuy, currentUnits: playerResources.units)
        
        let supplyCost = baseManager.getSupplyCost(ammo: ammoToBuy, food: foodToBuy)
        canAffordSupplies = playerResources.canAfford(supplyCost) &&
                           baseManager.canStoreSupplies(ammo: ammoToBuy, food: foodToBuy, currentResources: playerResources)
    }
    
    // MARK: - Resource Display Properties
    var resourcesString: String {
        return "Money: \(playerResources.money), Ammo: \(playerResources.ammo), Food: \(playerResources.food), Units: \(playerResources.units)"
    }
    
    var storageInfo: String {
        let capacity = baseManager.storageCapacity
        return "Storage Level \(baseManager.storageLevel) - Capacity: \(capacity.money) money, \(capacity.ammo) ammo, \(capacity.food) food"
    }
    
    var barracksInfo: String {
        return "Barracks Level \(baseManager.barracksLevel) - Max Units: \(baseManager.maxUnits)"
    }
    
    // MARK: - Building Upgrades
    func upgradeStorage() {
        guard canUpgradeStorage else {
            showError("Cannot upgrade storage", "Insufficient resources or already at max level")
            return
        }
        
        guard let gameManager = gameStateManager else {
            showError("Upgrade Failed", "Game state not available")
            return
        }
        
        let cost = baseManager.getUpgradeCost(for: .storage)
        
        // Spend resources through game manager
        if gameManager.spendResources(cost) {
            // Upgrade building through base manager
            if baseManager.upgradeBuilding(.storage, with: &playerResources) {
                // Sync resources back from game manager
                playerResources = gameManager.currentResources
                showSuccess("Storage Upgraded", "Storage capacity increased!")
                refreshData()
            } else {
                // Refund resources if upgrade failed
                gameManager.addResources(cost)
                showError("Upgrade Failed", "Unable to upgrade storage")
            }
        } else {
            showError("Upgrade Failed", "Insufficient resources")
        }
    }
    
    func upgradeBarracks() {
        guard canUpgradeBarracks else {
            showError("Cannot upgrade barracks", "Insufficient resources or already at max level")
            return
        }
        
        guard let gameManager = gameStateManager else {
            showError("Upgrade Failed", "Game state not available")
            return
        }
        
        let cost = baseManager.getUpgradeCost(for: .barracks)
        
        // Spend resources through game manager
        if gameManager.spendResources(cost) {
            // Upgrade building through base manager
            if baseManager.upgradeBuilding(.barracks, with: &playerResources) {
                // Sync resources back from game manager
                playerResources = gameManager.currentResources
                showSuccess("Barracks Upgraded", "Unit capacity increased!")
                refreshData()
            } else {
                // Refund resources if upgrade failed
                gameManager.addResources(cost)
                showError("Upgrade Failed", "Unable to upgrade barracks")
            }
        } else {
            showError("Upgrade Failed", "Insufficient resources")
        }
    }
    
    // MARK: - Unit Recruitment
    func recruitUnits() {
        guard unitsToBuy > 0 else {
            showError("Invalid Amount", "Must recruit at least 1 unit")
            return
        }
        
        guard canAffordUnits else {
            showError("Cannot Recruit Units", "Insufficient resources or barracks capacity")
            return
        }
        
        guard let gameManager = gameStateManager else {
            showError("Recruitment Failed", "Game state not available")
            return
        }
        
        // Use game manager's recruitment method
        if gameManager.recruitUnits(unitsToBuy) {
            // Sync resources from game manager
            playerResources = gameManager.currentResources
            showSuccess("Units Recruited", "Successfully recruited \(unitsToBuy) units")
            unitsToBuy = 1 // Reset to default
            refreshData()
        } else {
            showError("Recruitment Failed", "Unable to recruit units")
        }
    }
    
    // MARK: - Supply Purchases
    func purchaseSupplies() {
        guard ammoToBuy > 0 || foodToBuy > 0 else {
            showError("Invalid Purchase", "Must buy at least some ammo or food")
            return
        }
        
        guard canAffordSupplies else {
            showError("Cannot Purchase", "Insufficient money or storage capacity")
            return
        }
        
        guard let gameManager = gameStateManager else {
            showError("Purchase Failed", "Game state not available")
            return
        }
        
        // Use game manager's purchase method
        if gameManager.purchaseSupplies(ammo: ammoToBuy, food: foodToBuy) {
            // Sync resources from game manager
            playerResources = gameManager.currentResources
            showSuccess("Supplies Purchased", "Successfully bought \(ammoToBuy) ammo and \(foodToBuy) food")
            ammoToBuy = 0 // Reset
            foodToBuy = 0 // Reset
            refreshData()
        } else {
            showError("Purchase Failed", "Unable to purchase supplies")
        }
    }
    
    // MARK: - Cost Calculations
    func getUpgradeCost(for buildingType: BuildingType) -> Resource {
        return baseManager.getUpgradeCost(for: buildingType)
    }
    
    func getUnitRecruitmentCost() -> Resource {
        return baseManager.getUnitRecruitmentCost(unitsToBuy)
    }
    
    func getSupplyCost() -> Resource {
        return baseManager.getSupplyCost(ammo: ammoToBuy, food: foodToBuy)
    }
    
    // MARK: - Capacity Checks
    func getMaxRecruitableUnits() -> Int {
        return baseManager.maxRecruitableUnits(currentUnits: playerResources.units)
    }
    
    func getMaxAffordableUnits() -> Int {
        return economyManager.getMaxAffordableUnits(with: playerResources)
    }
    
    func getMaxAffordableAmmo() -> Int {
        let maxByMoney = economyManager.getMaxAffordableAmmo(with: playerResources)
        let maxByStorage = baseManager.storageCapacity.ammo - playerResources.ammo
        return min(maxByMoney, max(0, maxByStorage))
    }
    
    func getMaxAffordableFood() -> Int {
        let maxByMoney = economyManager.getMaxAffordableFood(with: playerResources)
        let maxByStorage = baseManager.storageCapacity.food - playerResources.food
        return min(maxByMoney, max(0, maxByStorage))
    }
    
    // MARK: - Quick Actions
    func buyMaxUnits() {
        let maxAffordable = getMaxAffordableUnits()
        let maxRecruiteable = getMaxRecruitableUnits()
        unitsToBuy = min(maxAffordable, maxRecruiteable)
        updateValidationStates()
    }
    
    func buyMaxAmmo() {
        ammoToBuy = getMaxAffordableAmmo()
        updateValidationStates()
    }
    
    func buyMaxFood() {
        foodToBuy = getMaxAffordableFood()
        updateValidationStates()
    }
    
    // MARK: - Base Status
    var baseStatusSummary: String {
        let validation = baseManager.validateBaseOperations(resources: playerResources)
        var summary = "Base Status: "
        
        if validation.isValid {
            summary += "Operational"
        } else {
            summary += "Issues detected"
        }
        
        if validation.hasWarnings {
            summary += " (Warnings present)"
        }
        
        return summary
    }
    
    func getBaseValidation() -> BaseValidation {
        return baseManager.validateBaseOperations(resources: playerResources)
    }
    
    // MARK: - Alert Handling
    private func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showUpgradeAlert = true
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showUpgradeAlert = true
    }
    
    func dismissAlert() {
        showUpgradeAlert = false
        showPurchaseAlert = false
        showRecruitmentAlert = false
        alertTitle = ""
        alertMessage = ""
    }
    
    // MARK: - Form Validation
    func validateUnitPurchase() {
        if unitsToBuy < 1 {
            unitsToBuy = 1
        }
        
        let maxPossible = min(getMaxAffordableUnits(), getMaxRecruitableUnits())
        if unitsToBuy > maxPossible {
            unitsToBuy = maxPossible
        }
        
        updateValidationStates()
    }
    
    func validateSupplyPurchase() {
        ammoToBuy = max(0, min(ammoToBuy, getMaxAffordableAmmo()))
        foodToBuy = max(0, min(foodToBuy, getMaxAffordableFood()))
        updateValidationStates()
    }
    
    // MARK: - Navigation Support
    var canLeaveBase: Bool {
        // Check if player has minimum resources to perform operations
        return playerResources.units > 0 && (playerResources.ammo > 0 || playerResources.food > 0)
    }
    
    var leaveBaseWarning: String? {
        if playerResources.units == 0 {
            return "You have no units! Recruit some before leaving."
        }
        
        if playerResources.ammo == 0 && playerResources.food == 0 {
            return "You have no supplies! Buy ammo and food before operations."
        }
        
        return nil
    }
    
    // MARK: - Game State Synchronization
    func syncWithGameState() {
        guard let gameManager = gameStateManager else { return }
        
        // Force refresh from game state
        playerResources = gameManager.currentResources
        updateValidationStates()
    }
    
    // MARK: - Debug Support
    var debugInfo: String {
        var info = "BaseViewModel Debug:\n"
        info += "Has GameManager: \(gameStateManager != nil)\n"
        info += "Resources: \(playerResources.totalValue) total value\n"
        info += "Storage Level: \(baseManager.storageLevel)\n"
        info += "Barracks Level: \(baseManager.barracksLevel)\n"
        info += "Can Leave Base: \(canLeaveBase)\n"
        
        return info
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Input Validation Extensions
extension BaseViewModel {
    func setUnitsToBuy(_ value: Int) {
        unitsToBuy = max(1, value)
        validateUnitPurchase()
    }
    
    func setAmmoToBuy(_ value: Int) {
        ammoToBuy = max(0, value)
        validateSupplyPurchase()
    }
    
    func setFoodToBuy(_ value: Int) {
        foodToBuy = max(0, value)
        validateSupplyPurchase()
    }
}
