import Foundation
import Combine

enum SaveResult {
    case success
    case failure(SaveError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

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

enum SaveError: Error, LocalizedError {
    case encodingFailed
    case storageFull
    case permissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode game data"
        case .storageFull:
            return "Not enough storage space"
        case .permissionDenied:
            return "Storage permission denied"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

enum LoadError: Error, LocalizedError {
    case noSaveFound
    case corruptedData
    case decodingFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSaveFound:
            return "No saved game found"
        case .corruptedData:
            return "Save data is corrupted"
        case .decodingFailed:
            return "Failed to decode save data"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

class GameSaveManager: ObservableObject {
    
    private let userDefaults = UserDefaults.standard
    private let saveKey = "GameSave_Data"
    private let saveInfoKey = "GameSave_Info"
    
    @Published var hasSavedGame: Bool = false
    @Published var saveInfo: String = ""
    @Published var lastSaveDate: Date?
    
    init() {
        checkForSavedGame()
    }
    
    func saveGame(_ gameState: GameState) -> SaveResult {
        do {
            let data = try JSONEncoder().encode(gameState)
            userDefaults.set(data, forKey: saveKey)
            
            let saveDate = Date()
            userDefaults.set(saveDate, forKey: saveInfoKey)
            
            lastSaveDate = saveDate
            updateSaveInfo(gameState, date: saveDate)
            hasSavedGame = true
            
            return .success
            
        } catch {
            return .failure(.encodingFailed)
        }
    }
    
    func loadGame() -> LoadResult {
        guard let data = userDefaults.data(forKey: saveKey) else {
            return .failure(.noSaveFound)
        }
        
        do {
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            return .success(gameState)
        } catch {
            return .failure(.decodingFailed)
        }
    }
    
    func deleteSave() {
        userDefaults.removeObject(forKey: saveKey)
        userDefaults.removeObject(forKey: saveInfoKey)
        
        hasSavedGame = false
        saveInfo = ""
        lastSaveDate = nil
    }
    
    func checkForSavedGame() {
        hasSavedGame = userDefaults.object(forKey: saveKey) != nil
        
        if hasSavedGame {
            if let saveDate = userDefaults.object(forKey: saveInfoKey) as? Date {
                lastSaveDate = saveDate
                
                let result = loadGame()
                if case .success(let gameState) = result {
                    updateSaveInfo(gameState, date: saveDate)
                } else {
                    saveInfo = "Corrupted save data"
                }
            } else {
                saveInfo = "Save found (unknown date)"
            }
        } else {
            saveInfo = ""
        }
    }
    
    private func updateSaveInfo(_ gameState: GameState, date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let progress = Int(gameState.completionPercentage * 100)
        let alertLevel = gameState.alertPercentage
        
        saveInfo = "Progress: \(progress)%, Alert: \(alertLevel)%"
    }
    
    func validateSave() -> Bool {
        let result = loadGame()
        return result.isSuccess
    }
}
