import Foundation

// MARK: - Economy Manager
class EconomyManager {
    
    // MARK: - Constants from TS
    private static let unitRecruitmentMoneyCost: Int = 100
    private static let unitRecruitmentFoodCost: Int = 5
    private static let ammoPricePerUnit: Int = 5
    private static let foodPricePerUnit: Int = 2
    
    // MARK: - Unit Recruitment (100 money + 5 food per unit)
    static func getUnitRecruitmentCost(count: Int) -> Resource {
        return Resource(
            money: count * unitRecruitmentMoneyCost,
            food: count * unitRecruitmentFoodCost
        )
    }
    
    static func canAffordUnitRecruitment(count: Int, with resources: Resource) -> Bool {
        let cost = getUnitRecruitmentCost(count: count)
        return resources.canAfford(cost)
    }
    
    static func getMaxAffordableUnits(with resources: Resource) -> Int {
        let maxByMoney = resources.money / unitRecruitmentMoneyCost
        let maxByFood = resources.food / unitRecruitmentFoodCost
        return min(maxByMoney, maxByFood)
    }
    
    // MARK: - Supply Purchases (Ammo = 5 money, Food = 2 money)
    static func getSupplyCost(ammo: Int = 0, food: Int = 0) -> Resource {
        let totalMoneyCost = (ammo * ammoPricePerUnit) + (food * foodPricePerUnit)
        return Resource(money: totalMoneyCost)
    }
    
    static func canAffordSupplies(ammo: Int = 0, food: Int = 0, with resources: Resource) -> Bool {
        let cost = getSupplyCost(ammo: ammo, food: food)
        return resources.canAfford(cost)
    }
    
    static func getMaxAffordableAmmo(with resources: Resource) -> Int {
        return resources.money / ammoPricePerUnit
    }
    
    static func getMaxAffordableFood(with resources: Resource) -> Int {
        return resources.money / foodPricePerUnit
    }
    
    // MARK: - Base Upgrades
    static func getBaseUpgradeCost(buildingType: BuildingType, currentLevel: Int) -> Resource {
        let building = Building(type: buildingType, level: currentLevel)
        return building.upgradeCost
    }
    
    static func canAffordBaseUpgrade(buildingType: BuildingType, currentLevel: Int, with resources: Resource) -> Bool {
        let cost = getBaseUpgradeCost(buildingType: buildingType, currentLevel: currentLevel)
        return resources.canAfford(cost)
    }
    
    // MARK: - Transaction Processing
    static func processUnitRecruitment(count: Int, playerResources: inout Resource) -> Bool {
        let cost = getUnitRecruitmentCost(count: count)
        guard playerResources.canAfford(cost) else { return false }
        
        playerResources -= cost
        playerResources.addValue(count, for: .units)
        return true
    }
    
    static func processSupplyPurchase(ammo: Int, food: Int, playerResources: inout Resource) -> Bool {
        let cost = getSupplyCost(ammo: ammo, food: food)
        guard playerResources.canAfford(cost) else { return false }
        
        playerResources -= cost
        playerResources.addValue(ammo, for: .ammo)
        playerResources.addValue(food, for: .food)
        return true
    }
    
    static func processBaseUpgrade(buildingType: BuildingType, playerBase: inout PlayerBase, playerResources: inout Resource) -> Bool {
        let building = playerBase.building(of: buildingType)
        let cost = building.upgradeCost
        
        guard playerResources.canAfford(cost) && !building.isMaxLevel else { return false }
        
        playerResources -= cost
        return playerBase.upgradeBuilding(buildingType)
    }
}
