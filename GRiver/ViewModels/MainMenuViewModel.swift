import Foundation
import Combine

// MARK: - Navigation Destination
enum NavigationDestination: String, CaseIterable {
    case mainMenu = "mainMenu"
    case gameMap = "gameMap"
    case operationResult = "operationResult"
    case gameOver = "gameOver"
    
    var displayName: String {
        switch self {
        case .mainMenu: return "Main Menu"
        case .gameMap: return "Global Map"
        case .operationResult: return "Operation Result"
        case .gameOver: return "Game Over"
        }
    }
}

// MARK: - Main Menu View Model
class MainMenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
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
    
    // MARK: - Navigation Publisher
    private let navigationSubject = PassthroughSubject<NavigationRequest, Never>()
    var navigationRequestPublisher: AnyPublisher<NavigationRequest, Never> {
        navigationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    private let gameSaveManager: GameSaveManager
    private var gameStateManager: GameStateManager?
    
    // MARK: - Initialization
    init() {
        self.gameSaveManager = GameSaveManager()
        checkForSavedGame()
    }
    
    // MARK: - Game State Management
    func updateGameState(_ gameManager: GameStateManager?) {
        self.gameStateManager = gameManager
        updateGameStatus()
    }
    
    private func updateGameStatus() {
        if let manager = gameStateManager {
            gameStatus = manager.currentStatus
            isGameActive = manager.isGameActive
        } else {
            gameStatus = .playing
            isGameActive = false
        }
    }
    
    // MARK: - Navigation Methods
    func handlePlayAction() {
        if isGameActive && gameStatus == .paused {
            // Resume existing game
            gameStateManager?.resumeGame()
            updateGameStatus()
            navigationSubject.send(.toGameMap)
        } else if hasSavedGame && !isGameActive {
            // Continue from save
            navigationSubject.send(.continueGame)
        } else {
            // Start new game
            if isGameActive && gameStateManager?.currentStatus == .playing {
                showNewGameConfirm = true
            } else {
                navigationSubject.send(.startNewGame)
            }
        }
    }
    
    func confirmNewGame() {
        showNewGameConfirm = false
        navigationSubject.send(.startNewGame)
    }
    
    // MARK: - Game Management
    func pauseGame() {
        gameStateManager?.pauseGame()
        updateGameStatus()
    }
    
    func resumeGame() {
        gameStateManager?.resumeGame()
        updateGameStatus()
    }
    
    func resetGame() {
        gameStateManager = nil
        isGameActive = false
        gameStatus = .playing
        checkForSavedGame()
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
    
    func saveCurrentGame() {
        guard let gameManager = gameStateManager else { return }
        
        let gameState = gameManager.exportGameState()
        let result = gameSaveManager.autoSave(gameState)
        
        switch result {
        case .success(let saveSlot):
            checkForSavedGame() // Refresh save info
            print("Game saved: \(saveSlot.displayInfo)")
            
        case .failure(let error):
            showLoadError(error.localizedDescription)
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
        // For now, just pause the game
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
    
    func showLoadError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showLoadError = true
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
        let testGameManager = GameStateManager()
        
        // Add some test resources
        testGameManager.addResources(Resource(money: 1000, ammo: 50, food: 100, units: 10))
        
        updateGameState(testGameManager)
    }
    
    func simulateGameProgress() {
        if gameStateManager == nil {
            createTestGameState()
        }
        
        guard let gameManager = gameStateManager else { return }
        
        // Simulate some game progress for testing
        gameManager.increaseAlert(by: 0.3)
        gameManager.addResources(Resource(money: 500, ammo: 20, food: 30, units: 5))
        updateGameStatus()
        saveCurrentGame()
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
    
    // MARK: - Deprecated Navigation Methods (kept for compatibility)
    @available(*, deprecated, message: "Use navigation publisher instead")
    func navigateToGameMap() {
        navigationSubject.send(.toGameMap)
    }
    
    @available(*, deprecated, message: "Use navigation publisher instead")
    func navigateToMainMenu() {
        navigationSubject.send(.toMainMenu)
    }
    
    @available(*, deprecated, message: "Use navigation publisher instead")
    func navigateToOperationResult() {
        // Operation results are handled by overlays now
    }
    
    @available(*, deprecated, message: "Use navigation publisher instead")
    func navigateToGameOver() {
        // Game over is handled automatically by coordinator
    }
    
    @available(*, deprecated, message: "Use navigation publisher instead")
    func navigateBack() {
        // Back navigation is handled by coordinator
    }
    
    // MARK: - Legacy Properties (kept for compatibility)
    @available(*, deprecated, message: "Navigation is handled by AppCoordinator")
    var currentDestination: NavigationDestination {
        return .mainMenu
    }
    
    @available(*, deprecated, message: "Navigation is handled by AppCoordinator")
    var navigationPath: [NavigationDestination] {
        return [.mainMenu]
    }
    
    @available(*, deprecated, message: "Navigation is handled by AppCoordinator")
    func canNavigateBack() -> Bool {
        return false
    }
}
