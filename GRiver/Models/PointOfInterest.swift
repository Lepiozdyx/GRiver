import Foundation
import CoreGraphics

// MARK: - Point of Interest Types
enum POIType: String, CaseIterable, Codable {
    case base = "base"
    case village = "village" 
    case warehouse = "warehouse"
    case station = "station"
    case factory = "factory"
    
    var displayName: String {
        switch self {
        case .base: return "Base"
        case .village: return "Village"
        case .warehouse: return "Warehouse" 
        case .station: return "Station"
        case .factory: return "Factory"
        }
    }
    
    var imageName: String {
        return self.rawValue
    }
    
    var size: CGSize {
        switch self {
        case .base: return CGSize(width: 70, height: 30)
        case .village: return CGSize(width: 90, height: 70)
        case .warehouse: return CGSize(width: 60, height: 60)
        case .station: return CGSize(width: 65, height: 65)
        case .factory: return CGSize(width: 75, height: 75)
        }
    }
    
    var baseDefense: Int {
        switch self {
        case .base: return 50
        case .village: return 20
        case .warehouse: return 30
        case .station: return 35
        case .factory: return 40
        }
    }
    
    var initialUnits: Int {
        switch self {
        case .base: return 15
        case .village: return 8
        case .warehouse: return 10
        case .station: return 12
        case .factory: return 13
        }
    }
}

// MARK: - POI Status
enum POIStatus: String, Codable {
    case active = "active"
    case captured = "captured"
    case destroyed = "destroyed"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .captured: return "Captured"
        case .destroyed: return "Destroyed"
        }
    }
}

// MARK: - Point of Interest Model
struct PointOfInterest: Identifiable, Codable, Equatable {
    var id = UUID()
    let type: POIType
    let position: CGPoint
    var status: POIStatus
    var currentDefense: Int
    var currentUnits: Int
    var defenseBonus: Int // Additional defense from global alert level
    
    // MARK: - Initialization
    init(type: POIType, position: CGPoint, status: POIStatus = .active) {
        self.type = type
        self.position = position
        self.status = status
        self.currentDefense = type.baseDefense
        self.currentUnits = type.initialUnits
        self.defenseBonus = 0
    }
    
    // MARK: - Combat Properties
    var totalDefense: Int {
        return currentDefense + defenseBonus
    }
    
    var totalStrength: Int {
        return totalDefense + currentUnits
    }
    
    var isOperational: Bool {
        return status == .active
    }
    
    var isCaptured: Bool {
        return status == .captured
    }
    
    var isDestroyed: Bool {
        return status == .destroyed
    }
    
    // MARK: - Reward Properties
    var raidReward: Resource {
        let multiplier = isHighValue ? 1.5 : 1.0
        return Resource(
            money: Int(Double(type.baseDefense) * 0.8 * multiplier),
            ammo: Int(Double(currentUnits) * 0.3 * multiplier),
            food: Int(Double(currentUnits) * 0.3 * multiplier),
            units: max(1, Int(Double(currentUnits) * 0.1 * multiplier))
        )
    }
    
    var robberyReward: Resource {
        let multiplier = isHighValue ? 1.5 : 1.0
        return Resource(
            money: Int(Double(type.baseDefense) * 1.0 * multiplier),
            ammo: Int(Double(currentUnits) * 0.5 * multiplier),
            food: Int(Double(currentUnits) * 0.5 * multiplier),
            units: max(1, Int(Double(currentUnits) * 0.15 * multiplier))
        )
    }
    
    var captureReward: Resource {
        let multiplier = isHighValue ? 2.0 : 1.5
        return Resource(
            money: Int(Double(type.baseDefense) * 1.5 * multiplier),
            ammo: Int(Double(currentUnits) * 0.8 * multiplier),
            food: Int(Double(currentUnits) * 0.8 * multiplier),
            units: max(2, Int(Double(currentUnits) * 0.25 * multiplier))
        )
    }
    
    var destructionReward: Resource {
        return Resource(money: 50, ammo: 10, food: 10, units: 1)
    }
    
    private var isHighValue: Bool {
        return type == .base || type == .factory
    }
    
    // MARK: - Mutating Methods
    mutating func applyDefenseBonus(_ bonus: Int) {
        defenseBonus += bonus
    }
    
    mutating func reinforceUnits(_ additionalUnits: Int) {
        currentUnits += additionalUnits
    }
    
    mutating func reduceUnits(_ reduction: Int) {
        currentUnits = max(0, currentUnits - reduction)
    }
    
    mutating func capture() {
        status = .captured
        currentUnits = 0
        currentDefense = 0
        defenseBonus = 0
    }
    
    mutating func destroy() {
        status = .destroyed
        currentUnits = 0
        currentDefense = 0
        defenseBonus = 0
    }
    
    // MARK: - Equatable
    static func == (lhs: PointOfInterest, rhs: PointOfInterest) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Collection Extensions
extension Array where Element == PointOfInterest {
    var activePOIs: [PointOfInterest] {
        return filter { $0.isOperational }
    }
    
    var capturedPOIs: [PointOfInterest] {
        return filter { $0.isCaptured }
    }
    
    var destroyedPOIs: [PointOfInterest] {
        return filter { $0.isDestroyed }
    }
    
    func poi(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return first { poi in
            let distance = sqrt(pow(poi.position.x - position.x, 2) + pow(poi.position.y - position.y, 2))
            return distance <= tolerance && poi.isOperational
        }
    }
}
