import Foundation
import Combine

// MARK: - Save Slot
struct SaveSlot: Codable, Identifiable {
    let id: UUID
    let name: String
    let saveDate: Date
    let gameProgress: Double
    let alertLevel: Int
    let totalResources: Int
    let operationsCount: Int
    let isValid: Bool
    
    init(gameState: GameState, name: String = "Auto Save") {
        self.id = gameState.gameID
        self.name = name
        self.saveDate = Date()
        self.gameProgress = gameState.completionPercentage
        self.alertLevel = gameState.alertPercentage
        self.totalResources = gameState.totalResourceValue
        self.operationsCount = gameState.statistics.operationsPerformed
        self.isValid = true
    }
    
    var displayInfo: String {
        let progressPercent = Int(gameProgress * 100)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return "\(name) - \(progressPercent)% complete, \(dateFormatter.string(from: saveDate))"
    }
    
    var shortInfo: String {
        let progressPercent = Int(gameProgress * 100)
        return "Progress: \(progressPercent)%, Alert: \(alertLevel)%"
    }
}

// MARK: - Save Result
enum SaveResult {
    case success(SaveSlot)
    case failure(SaveError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

// MARK: - Load Result
enum LoadResult {
    case success(GameState)
    case failure(LoadError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

// MARK: - Save Error
enum SaveError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case storageFull
    case permissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode game data"
        case .decodingFailed:
            return "Failed to decode game data"
        case .storageFull:
            return "Not enough storage space"
        case .permissionDenied:
            return "Storage permission denied"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Load Error
enum LoadError: Error, LocalizedError {
    case noSaveFound
    case corruptedData
    case incompatibleVersion
    case decodingFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSaveFound:
            return "No saved game found"
        case .corruptedData:
            return "Save data is corrupted"
        case .incompatibleVersion:
            return "Save from incompatible game version"
        case .decodingFailed:
            return "Failed to decode save data"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Game Save Manager
class GameSaveManager: ObservableObject {
    
    // MARK: - Constants
    private let userDefaults = UserDefaults.standard
    private let autoSaveKey = "AutoSave_GameState"
    private let saveSlotKey = "SaveSlot_Info"
    private let settingsKey = "GameSettings"
    private let maxSaveSlots = 5
    
    // MARK: - Published Properties
    @Published var currentSaveSlot: SaveSlot?
    @Published var availableSaves: [SaveSlot] = []
    @Published var lastSaveDate: Date?
    @Published var autoSaveEnabled: Bool = true
    
    // MARK: - Initialization
    init() {
        loadSaveSlotInfo()
        loadSettings()
    }
    
    // MARK: - Auto Save
    func autoSave(_ gameState: GameState) -> SaveResult {
        guard autoSaveEnabled else {
            return .failure(.permissionDenied)
        }
        
        return saveGame(gameState, to: autoSaveKey, slotName: "Auto Save")
    }
    
    func hasAutoSave() -> Bool {
        return userDefaults.object(forKey: autoSaveKey) != nil
    }
    
    func loadAutoSave() -> LoadResult {
        return loadGame(from: autoSaveKey)
    }
    
    func deleteAutoSave() {
        userDefaults.removeObject(forKey: autoSaveKey)
        
        // Remove from available saves if it exists
        availableSaves.removeAll { $0.name == "Auto Save" }
        saveSaveSlotInfo()
        
        if currentSaveSlot?.name == "Auto Save" {
            currentSaveSlot = nil
        }
    }
    
    // MARK: - Manual Save
    func saveGame(_ gameState: GameState, slotName: String = "Manual Save") -> SaveResult {
        let key = "ManualSave_\(slotName)_\(Date().timeIntervalSince1970)"
        return saveGame(gameState, to: key, slotName: slotName)
    }
    
    private func saveGame(_ gameState: GameState, to key: String, slotName: String) -> SaveResult {
        do {
            let data = try JSONEncoder().encode(gameState)
            userDefaults.set(data, forKey: key)
            
            let saveSlot = SaveSlot(gameState: gameState, name: slotName)
            updateSaveSlotInfo(saveSlot)
            
            lastSaveDate = Date()
            currentSaveSlot = saveSlot
            
            return .success(saveSlot)
            
        } catch {
            return .failure(.encodingFailed)
        }
    }
    
    // MARK: - Load Game
    func loadGame(from saveSlot: SaveSlot) -> LoadResult {
        // Find the key for this save slot
        let keys = getAllSaveKeys()
        
        for key in keys {
            let result = loadGame(from: key)
            if case .success(let gameState) = result,
               gameState.gameID == saveSlot.id {
                return result
            }
        }
        
        return .failure(.noSaveFound)
    }
    
    private func loadGame(from key: String) -> LoadResult {
        guard let data = userDefaults.data(forKey: key) else {
            return .failure(.noSaveFound)
        }
        
        do {
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            return .success(gameState)
        } catch {
            return .failure(.decodingFailed)
        }
    }
    
    // MARK: - Save Slot Management
    private func updateSaveSlotInfo(_ saveSlot: SaveSlot) {
        // Remove existing save with same ID
        availableSaves.removeAll { $0.id == saveSlot.id }
        
        // Add new save
        availableSaves.append(saveSlot)
        
        // Sort by date (newest first)
        availableSaves.sort { $0.saveDate > $1.saveDate }
        
        // Keep only max slots
        if availableSaves.count > maxSaveSlots {
            let removedSaves = Array(availableSaves.dropFirst(maxSaveSlots))
            availableSaves = Array(availableSaves.prefix(maxSaveSlots))
            
            // Clean up old saves from UserDefaults
            for oldSave in removedSaves {
                deleteGameData(for: oldSave)
            }
        }
        
        saveSaveSlotInfo()
    }
    
    private func saveSaveSlotInfo() {
        do {
            let data = try JSONEncoder().encode(availableSaves)
            userDefaults.set(data, forKey: saveSlotKey)
        } catch {
            print("Failed to save slot info: \(error)")
        }
    }
    
    private func loadSaveSlotInfo() {
        guard let data = userDefaults.data(forKey: saveSlotKey) else { return }
        
        do {
            availableSaves = try JSONDecoder().decode([SaveSlot].self, from: data)
            availableSaves.sort { $0.saveDate > $1.saveDate }
        } catch {
            print("Failed to load slot info: \(error)")
            availableSaves = []
        }
    }
    
    // MARK: - Delete Saves
    func deleteSave(_ saveSlot: SaveSlot) {
        availableSaves.removeAll { $0.id == saveSlot.id }
        deleteGameData(for: saveSlot)
        saveSaveSlotInfo()
        
        if currentSaveSlot?.id == saveSlot.id {
            currentSaveSlot = nil
        }
    }
    
    private func deleteGameData(for saveSlot: SaveSlot) {
        let keys = getAllSaveKeys()
        
        for key in keys {
            let result = loadGame(from: key)
            if case .success(let gameState) = result,
               gameState.gameID == saveSlot.id {
                userDefaults.removeObject(forKey: key)
                break
            }
        }
    }
    
    func deleteAllSaves() {
        let keys = getAllSaveKeys()
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        
        availableSaves.removeAll()
        currentSaveSlot = nil
        saveSaveSlotInfo()
    }
    
    // MARK: - Utility Methods
    private func getAllSaveKeys() -> [String] {
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        return allKeys.filter {
            $0.hasPrefix("AutoSave_") || $0.hasPrefix("ManualSave_")
        }
    }
    
    // MARK: - Settings
    private func loadSettings() {
        autoSaveEnabled = userDefaults.bool(forKey: "AutoSaveEnabled")
        if userDefaults.object(forKey: "AutoSaveEnabled") == nil {
            autoSaveEnabled = true // Default to enabled
        }
    }
    
    func saveSettings() {
        userDefaults.set(autoSaveEnabled, forKey: "AutoSaveEnabled")
    }
    
    // MARK: - Quick Access
    var hasSavedGames: Bool {
        return !availableSaves.isEmpty
    }
    
    var mostRecentSave: SaveSlot? {
        return availableSaves.first
    }
    
    func quickSave(_ gameState: GameState) -> SaveResult {
        return saveGame(gameState, slotName: "Quick Save")
    }
    
    func quickLoad() -> LoadResult? {
        guard let recentSave = mostRecentSave else { return nil }
        return loadGame(from: recentSave)
    }
    
    // MARK: - Validation
    func validateSave(_ saveSlot: SaveSlot) -> Bool {
        let result = loadGame(from: saveSlot)
        return result.isSuccess
    }
    
    func cleanupCorruptedSaves() {
        let validSaves = availableSaves.filter { validateSave($0) }
        
        if validSaves.count != availableSaves.count {
            availableSaves = validSaves
            saveSaveSlotInfo()
        }
    }
    
    // MARK: - Storage Info
    func getStorageInfo() -> (totalSaves: Int, totalSize: String) {
        let saveKeys = getAllSaveKeys()
        var totalSize = 0
        
        for key in saveKeys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += data.count
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        
        return (saveKeys.count, formatter.string(fromByteCount: Int64(totalSize)))
    }
    
    // MARK: - Export/Import (Future Feature)
    func exportSave(_ saveSlot: SaveSlot) -> Data? {
        let result = loadGame(from: saveSlot)
        guard case .success(let gameState) = result else { return nil }
        
        return try? JSONEncoder().encode(gameState)
    }
    
    func importSave(from data: Data) -> SaveResult {
        do {
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            return saveGame(gameState, slotName: "Imported Save")
        } catch {
            return .failure(.decodingFailed)
        }
    }
}
