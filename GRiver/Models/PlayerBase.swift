import Foundation

// MARK: - Building Type Enum
enum BuildingType: String, CaseIterable, Codable {
    case storage = "storage"  // Погреб
    case barracks = "barracks"  // Бараки
    
    var displayName: String {
        switch self {
        case .storage: return "Storage"
        case .barracks: return "Barracks"
        }
    }
    
    var description: String {
        switch self {
        case .storage: return "Increases resource storage limits"
        case .barracks: return "Increases unit capacity"
        }
    }
    
    var maxLevel: Int {
        return 10
    }
}

// MARK: - Building Model
struct Building: Codable {
    let type: BuildingType
    var level: Int
    
    init(type: BuildingType, level: Int = 1) {
        self.type = type
        self.level = max(1, min(level, type.maxLevel))
    }
    
    var isMaxLevel: Bool {
        return level >= type.maxLevel
    }
    
    var upgradeCost: Resource {
        let baseCost = 200
        let costMultiplier = Double(level) * 1.5
        let totalCost = Int(Double(baseCost) * costMultiplier)
        
        switch type {
        case .storage:
            return Resource(money: totalCost, ammo: level * 2, food: level * 3)
        case .barracks:
            return Resource(money: totalCost, ammo: level * 3, food: level * 2)
        }
    }
    
    var benefit: Int {
        switch type {
        case .storage:
            return level * 100 // Storage capacity per level
        case .barracks:
            return level * 5   // Unit capacity per level
        }
    }
    
    mutating func upgrade() -> Bool {
        guard !isMaxLevel else { return false }
        level += 1
        return true
    }
}

// MARK: - Player Base Model
struct PlayerBase: Codable {
    var storage: Building
    var barracks: Building
    
    // MARK: - Initialization
    init() {
        self.storage = Building(type: .storage, level: 1)
        self.barracks = Building(type: .barracks, level: 1)
    }
    
    init(storageLevel: Int, barracksLevel: Int) {
        self.storage = Building(type: .storage, level: storageLevel)
        self.barracks = Building(type: .barracks, level: barracksLevel)
    }
    
    // MARK: - Capacity Properties
    var storageCapacity: Resource {
        let baseCapacity = 500
        let bonusCapacity = storage.benefit
        let totalCapacity = baseCapacity + bonusCapacity
        
        return Resource(
            money: totalCapacity * 2,  // Money has higher storage limit
            ammo: totalCapacity,
            food: totalCapacity,
            units: maxUnits
        )
    }
    
    var maxUnits: Int {
        let baseUnits = 10
        return baseUnits + barracks.benefit
    }
    
    // MARK: - Building Access
    func building(of type: BuildingType) -> Building {
        switch type {
        case .storage: return storage
        case .barracks: return barracks
        }
    }
    
    mutating func upgradeBuilding(_ type: BuildingType) -> Bool {
        switch type {
        case .storage:
            return storage.upgrade()
        case .barracks:
            return barracks.upgrade()
        }
    }
    
    func canUpgradeBuilding(_ type: BuildingType, with resources: Resource) -> Bool {
        let building = building(of: type)
        guard !building.isMaxLevel else { return false }
        return resources.canAfford(building.upgradeCost)
    }
    
    func upgradeCost(for type: BuildingType) -> Resource {
        return building(of: type).upgradeCost
    }
    
    // MARK: - Resource Management
    func canStore(_ resources: Resource) -> Bool {
        let capacity = storageCapacity
        return resources.money <= capacity.money &&
               resources.ammo <= capacity.ammo &&
               resources.food <= capacity.food &&
               resources.units <= capacity.units
    }
    
    func getExcessResources(_ resources: Resource) -> Resource {
        let capacity = storageCapacity
        return Resource(
            money: max(0, resources.money - capacity.money),
            ammo: max(0, resources.ammo - capacity.ammo),
            food: max(0, resources.food - capacity.food),
            units: max(0, resources.units - capacity.units)
        )
    }
    
    func clampResourcesToCapacity(_ resources: Resource) -> Resource {
        let capacity = storageCapacity
        return Resource(
            money: min(resources.money, capacity.money),
            ammo: min(resources.ammo, capacity.ammo),
            food: min(resources.food, capacity.food),
            units: min(resources.units, capacity.units)
        )
    }
    
    // MARK: - Unit Management
    func canRecruitUnits(_ amount: Int, currentUnits: Int) -> Bool {
        return (currentUnits + amount) <= maxUnits
    }
    
    func maxRecruitableUnits(currentUnits: Int) -> Int {
        return max(0, maxUnits - currentUnits)
    }
    
    func unitRecruitmentCost(_ amount: Int) -> Resource {
        return Resource(
            money: amount * 100,
            food: amount * 5
        )
    }
    
    // MARK: - Supply Purchase
    func supplyCost(ammo: Int = 0, food: Int = 0) -> Resource {
        return Resource(
            money: (ammo * 5) + (food * 2)
        )
    }
    
    func canAffordSupplies(ammo: Int, food: Int, with resources: Resource) -> Bool {
        return resources.canAfford(supplyCost(ammo: ammo, food: food))
    }
    
    func canStoreSupplies(ammo: Int, food: Int, currentResources: Resource) -> Bool {
        let newResources = Resource(
            money: currentResources.money,
            ammo: currentResources.ammo + ammo,
            food: currentResources.food + food,
            units: currentResources.units
        )
        return canStore(newResources)
    }
    
    // MARK: - Base Statistics
    var totalBuildingLevels: Int {
        return storage.level + barracks.level
    }
    
    var baseValue: Int {
        return (storage.level * 200) + (barracks.level * 200)
    }
    
    var upgradeProgress: Double {
        let currentLevels = Double(totalBuildingLevels)
        let maxLevels = Double(BuildingType.allCases.count * BuildingType.storage.maxLevel)
        return currentLevels / maxLevels
    }
    
    // MARK: - Validation
    func validateResources(_ resources: Resource) -> Resource {
        return clampResourcesToCapacity(resources)
    }
    
    func hasSpaceForUnits(_ amount: Int, currentUnits: Int) -> Bool {
        return canRecruitUnits(amount, currentUnits: currentUnits)
    }
}
