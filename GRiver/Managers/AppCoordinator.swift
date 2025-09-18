import Foundation
import Combine
import SwiftUI

// MARK: - App Flow State
enum AppFlowState: String, CaseIterable {
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

// MARK: - App Coordinator
class AppCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFlow: AppFlowState = .mainMenu
    @Published var navigationPath = NavigationPath()
    @Published var showActionOverlay: Bool = false
    @Published var showOperationResult: Bool = false
    
    // Overlay state
    @Published var selectedPOI: PointOfInterest?
    @Published var overlayPosition: CGPoint = .zero
    @Published var currentOperationResult: OperationResult?
    
    // MARK: - Core Managers
    private(set) var gameStateManager: GameStateManager?
    private(set) var gameSaveManager: GameSaveManager
    private(set) var mainMenuViewModel: MainMenuViewModel
    
    // MARK: - ViewModels
    private var baseViewModel: BaseViewModel?
    private var gameSceneViewModel: GameSceneViewModel?
    private var actionOverlayViewModel: ActionOverlayViewModel?
    
    // MARK: - Initialization
    init() {
        self.gameSaveManager = GameSaveManager()
        self.mainMenuViewModel = MainMenuViewModel()
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for navigation changes from MainMenuViewModel
        mainMenuViewModel.$currentDestination
            .map { destination in
                switch destination {
                case .mainMenu: return .mainMenu
                case .gameMap: return .gameMap
                case .playerBase: return .playerBase
                case .operationResult: return .operationResult
                case .gameOver: return .gameOver
                }
            }
            .assign(to: &$currentFlow)
    }
    
    // MARK: - Navigation Methods
    func navigateToMainMenu() {
        withAnimation {
            currentFlow = .mainMenu
            navigationPath = NavigationPath()
            hideAllOverlays()
        }
        mainMenuViewModel.navigateToMainMenu()
    }
    
    func navigateToGameMap() {
        ensureGameStateManager()
        withAnimation {
            currentFlow = .gameMap
            navigationPath.append(AppFlowState.gameMap)
        }
        mainMenuViewModel.navigateToGameMap()
    }
    
    func navigateToPlayerBase() {
        ensureGameStateManager()
        withAnimation {
            currentFlow = .playerBase
            navigationPath.append(AppFlowState.playerBase)
        }
        mainMenuViewModel.navigateToPlayerBase()
    }
    
    func navigateToOperationResult() {
        withAnimation {
            currentFlow = .operationResult
            navigationPath.append(AppFlowState.operationResult)
        }
        mainMenuViewModel.navigateToOperationResult()
    }
    
    func navigateToGameOver() {
        withAnimation {
            currentFlow = .gameOver
            navigationPath.append(AppFlowState.gameOver)
        }
        mainMenuViewModel.navigateToGameOver()
    }
    
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        
        withAnimation {
            navigationPath.removeLast()
            
            if navigationPath.isEmpty {
                currentFlow = .mainMenu
            } else {
                // Determine current flow from navigation path
                updateCurrentFlowFromPath()
            }
        }
        
        mainMenuViewModel.navigateBack()
    }
    
    private func updateCurrentFlowFromPath() {
        // This is a simplified approach - in a real app you might want more sophisticated path tracking
        if navigationPath.count >= 2 {
            currentFlow = .operationResult
        } else if navigationPath.count == 1 {
            // Could be gameMap or playerBase - default to gameMap
            currentFlow = .gameMap
        } else {
            currentFlow = .mainMenu
        }
    }
    
    // MARK: - Game State Management
    private func ensureGameStateManager() {
        if gameStateManager == nil {
            gameStateManager = mainMenuViewModel.getGameStateManager()
        }
        
        // If still nil, create a new game
        if gameStateManager == nil {
            gameStateManager = GameStateManager()
            mainMenuViewModel.gameStateManager = gameStateManager
        }
    }
    
    func startNewGame() {
        gameStateManager = GameStateManager()
        mainMenuViewModel.gameStateManager = gameStateManager
        
        // Recreate ViewModels with new game state
        recreateViewModels()
    }
    
    func loadGame(from saveSlot: SaveSlot) -> Bool {
        let result = gameSaveManager.loadGame(from: saveSlot)
        
        switch result {
        case .success(let gameState):
            gameStateManager = GameStateManager(savedGameState: gameState)
            mainMenuViewModel.gameStateManager = gameStateManager
            recreateViewModels()
            return true
            
        case .failure:
            return false
        }
    }
    
    private func recreateViewModels() {
        guard let gameManager = gameStateManager else { return }
        
        // Recreate ViewModels with updated GameStateManager
        baseViewModel = BaseViewModel(gameStateManager: gameManager)
        gameSceneViewModel = GameSceneViewModel()
        actionOverlayViewModel = ActionOverlayViewModel(gameStateManager: gameManager)
    }
    
    // MARK: - ViewModel Access
    func getBaseViewModel() -> BaseViewModel {
        if baseViewModel == nil {
            ensureGameStateManager()
            baseViewModel = BaseViewModel(gameStateManager: gameStateManager!)
        }
        return baseViewModel!
    }
    
    func getGameSceneViewModel() -> GameSceneViewModel {
        if gameSceneViewModel == nil {
            gameSceneViewModel = GameSceneViewModel()
        }
        return gameSceneViewModel!
    }
    
    func getActionOverlayViewModel() -> ActionOverlayViewModel {
        if actionOverlayViewModel == nil {
            ensureGameStateManager()
            actionOverlayViewModel = ActionOverlayViewModel(gameStateManager: gameStateManager!)
        }
        return actionOverlayViewModel!
    }
    
    // MARK: - POI Interaction
    func handlePOISelected(_ poi: PointOfInterest, at position: CGPoint) {
        selectedPOI = poi
        overlayPosition = position
        
        let overlayViewModel = getActionOverlayViewModel()
        overlayViewModel.selectPOI(poi)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showActionOverlay = true
        }
    }
    
    func handlePOIDeselected() {
        hideActionOverlay()
    }
    
    func hideActionOverlay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showActionOverlay = false
        }
        
        selectedPOI = nil
        actionOverlayViewModel?.deselectPOI()
    }
    
    // MARK: - Operation Handling
    func executeOperation(actionType: ActionType, targetPOI: PointOfInterest) {
        guard let gameManager = gameStateManager else { return }
        
        hideActionOverlay()
        
        // Execute operation
        let result = gameManager.executeOperation(actionType: actionType, targetPOI: targetPOI)
        
        // Handle result
        handleOperationResult(result)
        
        // Check win/lose conditions
        checkGameEndConditions()
    }
    
    func handleOperationResult(_ result: OperationResult) {
        currentOperationResult = result
        
        // Auto-save after operation
        saveCurrentGame()
        
        // Show result
        withAnimation {
            showOperationResult = true
        }
    }
    
    func hideOperationResult() {
        withAnimation {
            showOperationResult = false
        }
        currentOperationResult = nil
    }
    
    // MARK: - Game End Conditions
    private func checkGameEndConditions() {
        guard let gameManager = gameStateManager else { return }
        
        if gameManager.isVictory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.navigateToGameOver()
            }
        } else if gameManager.isDefeat {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.navigateToGameOver()
            }
        }
    }
    
    // MARK: - Save/Load Integration
    func saveCurrentGame() {
        guard let gameManager = gameStateManager else { return }
        
        let gameState = gameManager.exportGameState()
        let result = gameSaveManager.autoSave(gameState)
        
        switch result {
        case .success:
            mainMenuViewModel.checkForSavedGame()
        case .failure(let error):
            print("Auto-save failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Overlay Management
    func hideAllOverlays() {
        showActionOverlay = false
        showOperationResult = false
        selectedPOI = nil
        currentOperationResult = nil
        actionOverlayViewModel?.reset()
    }
    
    // MARK: - App Lifecycle
    func handleAppDidEnterBackground() {
        if let gameManager = gameStateManager, gameManager.isGameActive {
            gameManager.pauseGame()
            saveCurrentGame()
        }
    }
    
    func handleAppWillEnterForeground() {
        if let gameManager = gameStateManager, gameManager.currentStatus == .paused {
            gameManager.resumeGame()
        }
    }
    
    // MARK: - Debug Support
    func resetToMainMenu() {
        gameStateManager = nil
        baseViewModel = nil
        gameSceneViewModel = nil
        actionOverlayViewModel = nil
        
        hideAllOverlays()
        navigateToMainMenu()
        
        mainMenuViewModel.resetGame()
    }
    
    var debugInfo: String {
        var info = "AppCoordinator Debug:\n"
        info += "Current Flow: \(currentFlow.displayName)\n"
        info += "Navigation Depth: \(navigationPath.count)\n"
        info += "Game Active: \(gameStateManager?.isGameActive ?? false)\n"
        info += "Overlays: ActionOverlay=\(showActionOverlay), Result=\(showOperationResult)\n"
        
        if let gameManager = gameStateManager {
            let state = gameManager.exportGameState()
            info += "Game State: \(state.status.displayName), Alert: \(state.alertPercentage)%\n"
        }
        
        return info
    }
    
    // MARK: - Public Interface for Views
    var isGameActive: Bool {
        return gameStateManager?.isGameActive ?? false
    }
    
    var currentGameState: GameState? {
        return gameStateManager?.exportGameState()
    }
    
    var canNavigateBack: Bool {
        return !navigationPath.isEmpty
    }
}

// MARK: - Coordinator Extensions for View Integration
extension AppCoordinator {
    
    // MARK: - Main Menu Integration
    func handleMainMenuPlayAction() {
        mainMenuViewModel.handlePlayAction()
    }
    
    func handleMainMenuBaseAction() {
        mainMenuViewModel.handleBaseAction()
    }
    
    // MARK: - Game Map Integration
    func createGameMapView() -> some View {
        let viewModel = getGameSceneViewModel()
        return GameMapView()
            .environmentObject(viewModel)
            .onReceive(NotificationCenter.default.publisher(for: .poiSelected)) { notification in
                if let userInfo = notification.userInfo,
                   let poi = userInfo["poi"] as? PointOfInterest,
                   let position = userInfo["position"] as? CGPoint {
                    self.handlePOISelected(poi, at: position)
                }
            }
    }
    
    // MARK: - Player Base Integration
    func createPlayerBaseView() -> some View {
        let viewModel = getBaseViewModel()
        return PlayerBaseView()
            .environmentObject(viewModel)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let poiSelected = Notification.Name("poiSelected")
    static let poiDeselected = Notification.Name("poiDeselected")
    static let operationCompleted = Notification.Name("operationCompleted")
}
