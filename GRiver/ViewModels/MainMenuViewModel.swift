import Foundation
import Combine

// MARK: - Navigation Destination
enum NavigationDestination: String, CaseIterable {
    case mainMenu = "mainMenu"
    case gameMap = "gameMap"
    case playerBase = "playerBase"
    case operationResult = "operationResult"
    case gameOver = "gameOver"
    
    var displayName: String {
        switch self {
        case .mainMenu: return "Main Menu"
        case .gameMap: return "Global Map"
        case .playerBase: return "Player Base"
        case .operationResult: return "Operation Result"
        case .gameOver: return "Game Over"
        }
    }
}

// MARK: - Game Launch Mode
enum GameLaunchMode: String {
    case newGame = "newGame"
    case continueGame = "continueGame"
    
    var displayName: String {
        switch self {
        case .newGame: return "New Game"
        case .continueGame: return "Continue Game"
        }
    }
}

// MARK: - Main Menu View Model
class MainMenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentDestination: NavigationDestination = .mainMenu
    @Published var gameStateManager: GameStateManager?
    @Published var hasSavedGame: Bool = false
    @Published var savedGameInfo: String = ""
    
    // Alert states
    @Published var showExitConfirm: Bool = false
    @Published var showNewGameConfirm: Bool = false
    @Published var showLoadError: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = "Alert"
    
    // Game state
    @Published var isGameActive: Bool = false
    @Published var gameStatus: GameStatus = .playing
    
    // MARK: - Dependencies
    private let gameSaveManager: GameSaveManager
    
    // MARK: - Initialization
    init() {
        self.gameSaveManager = GameSaveManager()
        checkForSavedGame()
    }
    
    // MARK: - Navigation Methods
    func navigateToGameMap() {
        ensureGameStateExists()
        currentDestination = .gameMap
    }
    
    func navigateToPlayerBase() {
        ensureGameStateExists()
        currentDestination = .playerBase
    }
    
    func navigateToMainMenu() {
        currentDestination = .mainMenu
    }
    
    func navigateToOperationResult() {
        currentDestination = .operationResult
    }
    
    func navigateToGameOver() {
        currentDestination = .gameOver
    }
    
    private func ensureGameStateExists() {
        if gameStateManager == nil {
            startNewGame()
        }
    }
    
    // MARK: - Game Management
    func startNewGame() {
        if isGameActive && gameStateManager?.currentStatus == .playing {
            showNewGameConfirm = true
            return
        }
        
        confirmNewGame()
    }
    
    func confirmNewGame() {
        gameStateManager = GameStateManager()
        isGameActive = true
        gameStatus = .playing
        showNewGameConfirm = false
        
        // Auto-save new game
        saveCurrentGame()
    }
    
    func continueGame() {
        if hasSavedGame {
            loadSavedGame()
        } else {
            startNewGame()
        }
    }
    
    func pauseGame() {
        gameStateManager?.pauseGame()
        updateGameStatus()
    }
    
    func resumeGame() {
        gameStateManager?.resumeGame()
        updateGameStatus()
    }
    
    func resetGame() {
        gameStateManager?.resetGame()
        isGameActive = false
        gameStatus = .playing
        checkForSavedGame()
    }
    
    private func updateGameStatus() {
        if let manager = gameStateManager {
            gameStatus = manager.currentStatus
            isGameActive = manager.isGameActive
        }
    }
    
    // MARK: - Save/Load Management
    func checkForSavedGame() {
        hasSavedGame = gameSaveManager.hasSavedGames
        if let recentSave = gameSaveManager.mostRecentSave {
            savedGameInfo = recentSave.displayInfo
        } else {
            savedGameInfo = "No saved games"
        }
    }
    
    private func loadSavedGame() {
        guard let recentSave = gameSaveManager.mostRecentSave else {
            alertTitle = "Load Failed"
            alertMessage = "No saved game found"
            showLoadError = true
            return
        }
        
        let result = gameSaveManager.loadGame(from: recentSave)
        
        switch result {
        case .success(let gameState):
            gameStateManager = GameStateManager(savedGameState: gameState)
            isGameActive = true
            updateGameStatus()
            
        case .failure(let error):
            alertTitle = "Load Failed"
            alertMessage = error.localizedDescription
            showLoadError = true
        }
    }
    
    func saveCurrentGame() {
        guard let gameManager = gameStateManager else { return }
        
        let gameState = gameManager.exportGameState()
        let result = gameSaveManager.autoSave(gameState)
        
        switch result {
        case .success(let saveSlot):
            checkForSavedGame() // Refresh save info
            print("Game saved: \(saveSlot.displayInfo)")
            
        case .failure(let error):
            alertTitle = "Save Failed"
            alertMessage = "Failed to save: \(error.localizedDescription)"
            showLoadError = true
        }
    }
    
    func deleteSavedGame() {
        guard let recentSave = gameSaveManager.mostRecentSave else { return }
        gameSaveManager.deleteSave(recentSave)
        checkForSavedGame()
    }
    
    // MARK: - Game Status Properties
    var canContinueGame: Bool {
        return hasSavedGame || (isGameActive && gameStateManager?.currentStatus == .paused)
    }
    
    var shouldShowContinueButton: Bool {
        return canContinueGame
    }
    
    var playButtonText: String {
        if isGameActive && gameStatus == .paused {
            return "Resume Game"
        } else if hasSavedGame && !isGameActive {
            return "Continue Game"
        } else {
            return "New Game"
        }
    }
    
    var gameProgressSummary: String {
        guard let gameManager = gameStateManager else {
            return hasSavedGame ? "Saved game available" : "No active game"
        }
        
        let state = gameManager.exportGameState()
        let progress = Int(state.completionPercentage * 100)
        let alertLevel = state.alertPercentage
        
        return "Progress: \(progress)%, Alert: \(alertLevel)%, Resources: \(state.totalResourceValue)"
    }
    
    // MARK: - Menu Actions
    func handlePlayAction() {
        if isGameActive && gameStatus == .paused {
            resumeGame()
            navigateToGameMap()
        } else if hasSavedGame && !isGameActive {
            continueGame()
            if isGameActive {
                navigateToGameMap()
            }
        } else {
            startNewGame()
            if isGameActive {
                navigateToGameMap()
            }
        }
    }
    
    func handleBaseAction() {
        if !isGameActive {
            startNewGame()
        }
        if isGameActive {
            navigateToPlayerBase()
        }
    }
    
    func handleExitAction() {
        if isGameActive && gameStatus == .playing {
            // Auto-save before exit
            saveCurrentGame()
        }
        showExitConfirm = true
    }
    
    func confirmExit() {
        showExitConfirm = false
        // In a real app, this would exit the app
        // For now, just reset to main menu
        pauseGame()
    }
    
    // MARK: - Alert Handling
    func dismissAlert() {
        showLoadError = false
        showNewGameConfirm = false
        showExitConfirm = false
        alertMessage = ""
        alertTitle = "Alert"
    }
    
    // MARK: - Game State Access
    func getCurrentGameState() -> GameState? {
        return gameStateManager?.exportGameState()
    }
    
    func getGameStateManager() -> GameStateManager? {
        return gameStateManager
    }
    
    func getGameSaveManager() -> GameSaveManager {
        return gameSaveManager
    }
    
    // MARK: - Development/Debug Support
    func createTestGameState() {
        gameStateManager = GameStateManager()
        
        // Add some test resources
        gameStateManager?.addResources(Resource(money: 1000, ammo: 50, food: 100, units: 10))
        
        isGameActive = true
        gameStatus = .playing
    }
    
    func simulateGameProgress() {
        guard let gameManager = gameStateManager else {
            createTestGameState()
            return
        }
        
        // Simulate some game progress for testing
        gameManager.increaseAlert(by: 0.3)
        gameManager.addResources(Resource(money: 500, ammo: 20, food: 30, units: 5))
        updateGameStatus()
        checkForSavedGame()
    }
    
    var debugInfo: String {
        guard let gameManager = gameStateManager else {
            return "No active game"
        }
        
        let state = gameManager.exportGameState()
        return """
        Game Status: \(state.status.displayName)
        Alert Level: \(state.alertPercentage)%
        Active POIs: \(state.activePOIs.count)/\(state.totalPOIs)
        Resources: \(state.resources.totalValue) total value
        Operations: \(state.statistics.operationsPerformed)
        Success Rate: \(Int(state.statistics.successRate * 100))%
        """
    }
    
    // MARK: - Navigation State
    var navigationPath: [NavigationDestination] {
        switch currentDestination {
        case .mainMenu:
            return [.mainMenu]
        case .gameMap:
            return [.mainMenu, .gameMap]
        case .playerBase:
            return [.mainMenu, .playerBase]
        case .operationResult:
            return [.mainMenu, .gameMap, .operationResult]
        case .gameOver:
            return [.mainMenu, .gameMap, .gameOver]
        }
    }
    
    func canNavigateBack() -> Bool {
        return currentDestination != .mainMenu
    }
    
    func navigateBack() {
        switch currentDestination {
        case .mainMenu:
            break
        case .gameMap, .playerBase:
            navigateToMainMenu()
        case .operationResult, .gameOver:
            navigateToGameMap()
        }
    }
}
