import Foundation
import Combine

enum Achievement: String, CaseIterable, Codable {
    case money1000 = "money1000"
    case defeatByAlert = "defeatByAlert"
    case units100 = "units100"
    case ammo1000 = "ammo1000"
    case victory = "victory"
}

class AchievementsManager: ObservableObject {
    static let shared = AchievementsManager()
    
    @Published private var unlockedAchievements: Set<Achievement> = []
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "UnlockedAchievements"
    
    private init() {
        loadAchievements()
    }
    
    func unlock(_ achievement: Achievement) {
        guard !unlockedAchievements.contains(achievement) else { return }
        
        unlockedAchievements.insert(achievement)
        saveAchievements()
    }
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        return unlockedAchievements.contains(achievement)
    }
    
    private func saveAchievements() {
        let achievementStrings = unlockedAchievements.map { $0.rawValue }
        userDefaults.set(achievementStrings, forKey: achievementsKey)
    }
    
    private func loadAchievements() {
        if let achievementStrings = userDefaults.array(forKey: achievementsKey) as? [String] {
            unlockedAchievements = Set(achievementStrings.compactMap { Achievement(rawValue: $0) })
        }
    }
}
