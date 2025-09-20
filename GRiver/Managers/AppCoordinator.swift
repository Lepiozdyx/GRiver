import Foundation
import Combine
import SwiftUI

enum AppFlowState: String, CaseIterable {
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

class AppCoordinator: ObservableObject {
    
    @Published var currentFlow: AppFlowState = .mainMenu
    @Published var navigationPath = NavigationPath()
    @Published var showActionOverlay: Bool = false
    @Published var showOperationResult: Bool = false
    @Published var showBaseOverlay: Bool = false
    
    @Published var selectedPOI: PointOfInterest?
    @Published var overlayPosition: CGPoint = .zero
    @Published var currentOperationResult: OperationResult?
    
    private(set) var gameStateManager: GameStateManager?
    private(set) var gameSaveManager: GameSaveManager
    private(set) var mainMenuViewModel: MainMenuViewModel
    
    private var baseViewModel: BaseViewModel?
    private var gameSceneViewModel: GameSceneViewModel?
    private var actionOverlayViewModel: ActionOverlayViewModel?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.gameSaveManager = GameSaveManager()
        self.mainMenuViewModel = MainMenuViewModel()
        setupBindings()
    }
    
    private func setupBindings() {
        mainMenuViewModel.navigationRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                self?.handleNavigationRequest(request)
            }
            .store(in: &cancellables)
    }
    
    private func handleNavigationRequest(_ request: NavigationRequest) {
        switch request {
        case .toGameMap:
            navigateToGameMap()
        case .toMainMenu:
            navigateToMainMenu()
        case .startNewGame:
            handleStartNewGame()
        case .continueGame:
            handleContinueGame()
        }
    }
    
    private func handleStartNewGame() {
        startNewGame()
        navigateToGameMap()
    }
    
    private func handleContinueGame() {
        let result = gameSaveManager.loadGame()
        switch result {
        case .success(let gameState):
            initializeGameState(GameStateManager(savedGameState: gameState))
            navigateToGameMap()
        case .failure(let error):
            mainMenuViewModel.showLoadError(error.localizedDescription)
            handleStartNewGame()
        }
    }
    
    func navigateToMainMenu() {
        if let gameManager = gameStateManager, gameManager.isGameActive {
            let gameState = gameManager.exportGameState()
            let _ = gameSaveManager.saveGame(gameState)
        }
        
        mainMenuViewModel.resetGameSession()
        mainMenuViewModel.checkForSavedGame()
        
        withAnimation {
            currentFlow = .mainMenu
            navigationPath = NavigationPath()
            hideAllOverlays()
        }
    }
    
    func navigateToGameMap() {
        ensureGameStateManager()
        withAnimation {
            currentFlow = .gameMap
            if navigationPath.isEmpty {
                navigationPath.append(AppFlowState.gameMap)
            }
        }
    }
    
    func navigateToOperationResult() {
        withAnimation {
            currentFlow = .operationResult
            navigationPath.append(AppFlowState.operationResult)
        }
    }
    
    func navigateToGameOver() {
        withAnimation {
            currentFlow = .gameOver
            navigationPath.append(AppFlowState.gameOver)
        }
    }
    
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        
        withAnimation {
            navigationPath.removeLast()
            
            if navigationPath.isEmpty {
                currentFlow = .mainMenu
            } else {
                updateCurrentFlowFromPath()
            }
        }
    }
    
    private func updateCurrentFlowFromPath() {
        if navigationPath.count >= 2 {
            currentFlow = .operationResult
        } else if navigationPath.count == 1 {
            currentFlow = .gameMap
        } else {
            currentFlow = .mainMenu
        }
    }
    
    func showBaseManagement() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showBaseOverlay = true
        }
    }
    
    func hideBaseManagement() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showBaseOverlay = false
        }
    }
    
    private func ensureGameStateManager() {
        if gameStateManager == nil {
            startNewGame()
        }
    }
    
    func startNewGame() {
        let newGameState = GameStateManager()
        initializeGameState(newGameState)
    }
    
    private func initializeGameState(_ gameState: GameStateManager) {
        gameStateManager = gameState
        mainMenuViewModel.updateGameState(gameStateManager)
        createViewModels()
    }
    
    private func createViewModels() {
        guard let gameManager = gameStateManager else { return }
        
        baseViewModel = BaseViewModel(gameStateManager: gameManager)
        gameSceneViewModel = GameSceneViewModel(gameStateManager: gameManager)
        actionOverlayViewModel = ActionOverlayViewModel(gameStateManager: gameManager)
    }
    
    func getBaseViewModel() -> BaseViewModel {
        if baseViewModel == nil {
            ensureGameStateManager()
            baseViewModel = BaseViewModel(gameStateManager: gameStateManager!)
        }
        return baseViewModel!
    }
    
    func getGameSceneViewModel() -> GameSceneViewModel {
        if gameSceneViewModel == nil {
            ensureGameStateManager()
            gameSceneViewModel = GameSceneViewModel(gameStateManager: gameStateManager)
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
    
    func executeOperation(actionType: ActionType, targetPOI: PointOfInterest) {
        guard let gameManager = gameStateManager else { return }
        
        hideActionOverlay()
        
        let result = gameManager.executeOperation(actionType: actionType, targetPOI: targetPOI)
        
        handleOperationResult(result)
        checkGameEndConditions()
        updateViewModelsData()
    }
    
    func handleOperationResult(_ result: OperationResult) {
        currentOperationResult = result
        
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
    
    private func updateViewModelsData() {
        baseViewModel?.refreshData()
        gameSceneViewModel?.updateMapData()
        mainMenuViewModel.updateGameState(gameStateManager)
    }
    
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
    
    func hideAllOverlays() {
        showActionOverlay = false
        showOperationResult = false
        showBaseOverlay = false
        selectedPOI = nil
        currentOperationResult = nil
        actionOverlayViewModel?.reset()
    }
    
    func handleAppDidEnterBackground() {
        if let gameManager = gameStateManager, gameManager.isGameActive {
            gameManager.pauseGame()
        }
    }
    
    func handleAppWillEnterForeground() {
        if let gameManager = gameStateManager, gameManager.currentStatus == .paused {
            gameManager.resumeGame()
        }
    }
    
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
        info += "Overlays: ActionOverlay=\(showActionOverlay), Result=\(showOperationResult), Base=\(showBaseOverlay)\n"
        
        if let gameManager = gameStateManager {
            let state = gameManager.exportGameState()
            info += "Game State: \(state.status.displayName), Alert: \(state.alertPercentage)%\n"
        }
        
        return info
    }
    
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

enum NavigationRequest {
    case toGameMap
    case toMainMenu
    case startNewGame
    case continueGame
}

extension Notification.Name {
    static let poiSelected = Notification.Name("poiSelected")
    static let poiDeselected = Notification.Name("poiDeselected")
    static let operationCompleted = Notification.Name("operationCompleted")
}
