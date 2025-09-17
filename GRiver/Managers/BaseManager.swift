import Foundation

// MARK: - Base Manager
class BaseManager {
    private(set) var playerBase: PlayerBase
    
    // MARK: - Initialization
    init() {
        self.playerBase = PlayerBase()
    }
    
    init(base: PlayerBase) {
        self.playerBase = base
    }
    
    // MARK: - Building Access
    var storageLevel: Int {
        return playerBase.storage.level
    }
    
    var barracksLevel: Int {
        return playerBase.barracks.level
    }
    
    var storageCapacity: Resource {
        return playerBase.storageCapacity
    }
    
    var maxUnits: Int {
        return playerBase.maxUnits
    }
    
    // MARK: - Building Upgrades
    func canUpgradeStorage(with resources: Resource) -> Bool {
        return playerBase.canUpgradeBuilding(.storage, with: resources)
    }
    
    func canUpgradeBarracks(with resources: Resource) -> Bool {
        return playerBase.canUpgradeBuilding(.barracks, with: resources)
    }
    
    func getUpgradeCost(for buildingType: BuildingType) -> Resource {
        return playerBase.upgradeCost(for: buildingType)
    }
    
    func upgradeBuilding(_ buildingType: BuildingType, with resources: inout Resource) -> Bool {
        let cost = getUpgradeCost(for: buildingType)
        guard resources.canAfford(cost) else { return false }
        
        let success = playerBase.upgradeBuilding(buildingType)
        if success {
            resources -= cost
        }
        return success
    }
    
    // MARK: - Resource Management
    func validateResourceLimits(_ resources: Resource) -> Resource {
        return playerBase.validateResources(resources)
    }
    
    func canStoreResources(_ resources: Resource) -> Bool {
        return playerBase.canStore(resources)
    }
    
    func getExcessResources(_ resources: Resource) -> Resource {
        return playerBase.getExcessResources(resources)
    }
    
    // MARK: - Unit Management
    func canRecruitUnits(_ count: Int, currentUnits: Int) -> Bool {
        return playerBase.canRecruitUnits(count, currentUnits: currentUnits)
    }
    
    func maxRecruitableUnits(currentUnits: Int) -> Int {
        return playerBase.maxRecruitableUnits(currentUnits: currentUnits)
    }
    
    func getUnitRecruitmentCost(_ count: Int) -> Resource {
        return playerBase.unitRecruitmentCost(count)
    }
    
    func recruitUnits(_ count: Int, currentUnits: Int, resources: inout Resource) -> Bool {
        guard canRecruitUnits(count, currentUnits: currentUnits) else { return false }
        
        let cost = getUnitRecruitmentCost(count)
        guard resources.canAfford(cost) else { return false }
        
        resources -= cost
        resources.addValue(count, for: .units)
        return true
    }
    
    // MARK: - Supply Purchases
    func canAffordSupplies(ammo: Int, food: Int, resources: Resource) -> Bool {
        return playerBase.canAffordSupplies(ammo: ammo, food: food, with: resources)
    }
    
    func canStoreSupplies(ammo: Int, food: Int, currentResources: Resource) -> Bool {
        return playerBase.canStoreSupplies(ammo: ammo, food: food, currentResources: currentResources)
    }
    
    func getSupplyCost(ammo: Int, food: Int) -> Resource {
        return playerBase.supplyCost(ammo: ammo, food: food)
    }
    
    func purchaseSupplies(ammo: Int, food: Int, resources: inout Resource) -> Bool {
        let cost = getSupplyCost(ammo: ammo, food: food)
        guard resources.canAfford(cost) && canStoreSupplies(ammo: ammo, food: food, currentResources: resources) else { 
            return false 
        }
        
        resources -= cost
        resources.addValue(ammo, for: .ammo)
        resources.addValue(food, for: .food)
        return true
    }
    
    // MARK: - Base Status
    func getBuildingInfo(_ buildingType: BuildingType) -> Building {
        return playerBase.building(of: buildingType)
    }
    
    var totalBuildingLevels: Int {
        return playerBase.totalBuildingLevels
    }
    
    var baseValue: Int {
        return playerBase.baseValue
    }
    
    // MARK: - Validation
    func validateBaseOperations(resources: Resource) -> BaseValidation {
        var issues: [String] = []
        var warnings: [String] = []
        
        let capacity = storageCapacity
        
        // Check storage limits
        if resources.money > capacity.money {
            issues.append("Money exceeds storage capacity")
        }
        if resources.ammo > capacity.ammo {
            issues.append("Ammo exceeds storage capacity")  
        }
        if resources.food > capacity.food {
            issues.append("Food exceeds storage capacity")
        }
        if resources.units > capacity.units {
            issues.append("Units exceed barracks capacity")
        }
        
        // Storage warnings (near capacity)
        if resources.money > Int(Double(capacity.money) * 0.9) {
            warnings.append("Money storage nearly full")
        }
        if resources.ammo > Int(Double(capacity.ammo) * 0.9) {
            warnings.append("Ammo storage nearly full")
        }
        if resources.food > Int(Double(capacity.food) * 0.9) {
            warnings.append("Food storage nearly full")
        }
        if resources.units >= maxUnits {
            warnings.append("Unit capacity reached")
        }
        
        return BaseValidation(isValid: issues.isEmpty, issues: issues, warnings: warnings)
    }
    
    // MARK: - Save/Load Support
    func exportBase() -> PlayerBase {
        return playerBase
    }
    
    func importBase(_ base: PlayerBase) {
        playerBase = base
    }
    
    // MARK: - Reset
    func resetBase() {
        playerBase = PlayerBase()
    }
}

// MARK: - Base Validation
struct BaseValidation {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
    
    var errorMessage: String {
        return issues.joined(separator: ", ")
    }
    
    var warningMessage: String {
        return warnings.joined(separator: ", ")
    }
}
