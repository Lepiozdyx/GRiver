import Foundation
import Combine

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

class MainMenuViewModel: ObservableObject {
    
    @Published var hasSavedGame: Bool = false
    @Published var savedGameInfo: String = ""
    
    @Published var showNewGameConfirm: Bool = false
    @Published var showLoadError: Bool = false
    @Published var showDeleteConfirm: Bool = false
    @Published var showManageProgress: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = "Alert"
    
    @Published var isGameActive: Bool = false
    @Published var gameStatus: GameStatus = .playing
    
    private let navigationSubject = PassthroughSubject<NavigationRequest, Never>()
    var navigationRequestPublisher: AnyPublisher<NavigationRequest, Never> {
        navigationSubject.eraseToAnyPublisher()
    }
    
    private let gameSaveManager: GameSaveManager
    private var gameStateManager: GameStateManager?
    
    init() {
        self.gameSaveManager = GameSaveManager()
        checkForSavedGame()
    }
    
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
    
    func handlePlayAction() {
        if hasSavedGame && !isGameActive {
            navigationSubject.send(.continueGame)
        } else {
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
    
    func handleManageProgress() {
        showManageProgress.toggle()
    }
    
    func handleDeleteProgress() {
        if hasSavedGame {
            showDeleteConfirm = true
        }
    }
    
    func confirmDeleteSave() {
        gameSaveManager.deleteSave()
        checkForSavedGame()
        showDeleteConfirm = false
        showManageProgress = false
        resetGame()
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
        gameStateManager = nil
        isGameActive = false
        gameStatus = .playing
        checkForSavedGame()
    }
    
    func checkForSavedGame() {
        gameSaveManager.checkForSavedGame()
        hasSavedGame = gameSaveManager.hasSavedGame
        savedGameInfo = gameSaveManager.saveInfo
    }
    
    var playButtonText: String {
        if hasSavedGame && !isGameActive {
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
    
    func dismissAlert() {
        showLoadError = false
        showNewGameConfirm = false
        showDeleteConfirm = false
        alertMessage = ""
        alertTitle = "Alert"
    }
    
    func showLoadError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showLoadError = true
    }
    
    func getCurrentGameState() -> GameState? {
        return gameStateManager?.exportGameState()
    }
    
    func getGameStateManager() -> GameStateManager? {
        return gameStateManager
    }
    
    func getGameSaveManager() -> GameSaveManager {
        return gameSaveManager
    }
}
