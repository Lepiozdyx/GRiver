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
    
    @Published var showLoadError: Bool = false
    @Published var showDeleteConfirm: Bool = false
    @Published var showManageProgress: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = "Alert"
    
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
    }
    
    func resetGameSession() {
        self.gameStateManager = nil
    }
    
    func handlePlayAction() {
        if hasSavedGame {
            navigationSubject.send(.continueGame)
        } else {
            navigationSubject.send(.startNewGame)
        }
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
        resetGameSession()
    }
    
    func resetGame() {
        gameStateManager = nil
        checkForSavedGame()
    }
    
    func checkForSavedGame() {
        gameSaveManager.checkForSavedGame()
        hasSavedGame = gameSaveManager.hasSavedGame
        savedGameInfo = gameSaveManager.saveInfo
    }
    
    var playButtonText: String {
        return hasSavedGame ? "Continue" : "Play"
    }
    
    func dismissAlert() {
        showLoadError = false
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
