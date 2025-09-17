import Foundation

// MARK: - Resource Model
struct Resource: Codable, Equatable {
    var money: Int
    var ammo: Int
    var food: Int
    var units: Int
    
    // MARK: - Initialization
    init(money: Int = 0, ammo: Int = 0, food: Int = 0, units: Int = 0) {
        self.money = max(0, money)
        self.ammo = max(0, ammo)
        self.food = max(0, food)
        self.units = max(0, units)
    }
    
    // MARK: - Static Presets
    static let zero = Resource()
    
    static let startingResources = Resource(
        money: 500,
        ammo: 20,
        food: 30,
        units: 5
    )
    
    // MARK: - Resource Operations
    mutating func add(_ other: Resource) {
        money += other.money
        ammo += other.ammo
        food += other.food
        units += other.units
    }
    
    mutating func subtract(_ other: Resource) {
        money = max(0, money - other.money)
        ammo = max(0, ammo - other.ammo)
        food = max(0, food - other.food)
        units = max(0, units - other.units)
    }
    
    func canAfford(_ cost: Resource) -> Bool {
        return money >= cost.money &&
               ammo >= cost.ammo &&
               food >= cost.food &&
               units >= cost.units
    }
    
    func multiplied(by factor: Double) -> Resource {
        return Resource(
            money: Int(Double(money) * factor),
            ammo: Int(Double(ammo) * factor),
            food: Int(Double(food) * factor),
            units: Int(Double(units) * factor)
        )
    }
    
    // MARK: - Combat Calculations
    var combatStrength: Double {
        return Double(units) + (Double(ammo) * 0.5) + (Double(food) * 0.2)
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return money >= 0 && ammo >= 0 && food >= 0 && units >= 0
    }
    
    var isEmpty: Bool {
        return money == 0 && ammo == 0 && food == 0 && units == 0
    }
    
    var hasUnits: Bool {
        return units > 0
    }
    
    var hasSupplies: Bool {
        return ammo > 0 || food > 0
    }
    
    // MARK: - Display Properties
    var totalValue: Int {
        // Rough estimate of total resource value in money equivalent
        return money + (ammo * 5) + (food * 2) + (units * 105) // 100 money + 5 food per unit
    }
    
    func formattedString(for type: ResourceType) -> String {
        switch type {
        case .money: return "\(money)"
        case .ammo: return "\(ammo)"
        case .food: return "\(food)"
        case .units: return "\(units)"
        }
    }
    
    // MARK: - Individual Resource Access
    func value(for type: ResourceType) -> Int {
        switch type {
        case .money: return money
        case .ammo: return ammo
        case .food: return food
        case .units: return units
        }
    }
    
    mutating func setValue(_ value: Int, for type: ResourceType) {
        let clampedValue = max(0, value)
        switch type {
        case .money: money = clampedValue
        case .ammo: ammo = clampedValue
        case .food: food = clampedValue
        case .units: units = clampedValue
        }
    }
    
    mutating func addValue(_ value: Int, for type: ResourceType) {
        switch type {
        case .money: money += value
        case .ammo: ammo += value
        case .food: food += value
        case .units: units += value
        }
        // Ensure no negative values
        money = max(0, money)
        ammo = max(0, ammo)
        food = max(0, food)
        units = max(0, units)
    }
}

// MARK: - Resource Type Enum
enum ResourceType: String, CaseIterable, Codable {
    case money = "money"
    case ammo = "ammo"
    case food = "food"
    case units = "units"
    
    var displayName: String {
        switch self {
        case .money: return "Money"
        case .ammo: return "Ammo"
        case .food: return "Food"
        case .units: return "Units"
        }
    }
    
    var symbol: String {
        switch self {
        case .money: return "$"
        case .ammo: return "🔫"
        case .food: return "🍖"
        case .units: return "👤"
        }
    }
    
    var unitCost: Resource {
        // Cost to hire one unit
        switch self {
        case .money: return Resource(money: 100)
        case .ammo: return Resource(money: 5)
        case .food: return Resource(money: 2)
        case .units: return Resource(money: 100, food: 5)
        }
    }
}

// MARK: - Arithmetic Operators
extension Resource {
    static func + (lhs: Resource, rhs: Resource) -> Resource {
        return Resource(
            money: lhs.money + rhs.money,
            ammo: lhs.ammo + rhs.ammo,
            food: lhs.food + rhs.food,
            units: lhs.units + rhs.units
        )
    }
    
    static func - (lhs: Resource, rhs: Resource) -> Resource {
        return Resource(
            money: max(0, lhs.money - rhs.money),
            ammo: max(0, lhs.ammo - rhs.ammo),
            food: max(0, lhs.food - rhs.food),
            units: max(0, lhs.units - rhs.units)
        )
    }
    
    static func += (lhs: inout Resource, rhs: Resource) {
        lhs.add(rhs)
    }
    
    static func -= (lhs: inout Resource, rhs: Resource) {
        lhs.subtract(rhs)
    }
    
    static func * (lhs: Resource, rhs: Double) -> Resource {
        return lhs.multiplied(by: rhs)
    }
}

// MARK: - Resource Costs Constants
extension Resource {
    // Unit recruitment costs
    static let unitRecruitmentCost = Resource(money: 100, food: 5)
    
    // Supply costs per unit
    static let ammoCost = Resource(money: 5)
    static let foodCost = Resource(money: 2)
    
    // Operation base costs (consumed regardless of outcome)
    static let raidCost = Resource(ammo: 2, food: 1)
    static let robberyCost = Resource(ammo: 3, food: 2)
    static let captureCost = Resource(ammo: 5, food: 3, units: 1)
    static let destructionCost = Resource(ammo: 8, food: 2)
    
    // Failure penalties (additional losses on failed operations)
    static let failurePenalty = Resource(ammo: 2, food: 1, units: 1)
}
