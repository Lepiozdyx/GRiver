import Foundation
import Combine
import SpriteKit

class GameSceneViewModel: ObservableObject {
    
    @Published var selectedPOI: PointOfInterest?
    @Published var showActionOverlay: Bool = false
    @Published var overlayPosition: CGPoint = .zero
    @Published var isSceneReady: Bool = false
    @Published var scene: GameScene?
    
    private var gameStateManager: GameStateManager?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationObservers()
    }
    
    convenience init(gameStateManager: GameStateManager?) {
        self.init()
        setGameStateManager(gameStateManager)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .sceneDidBecomeReady)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSceneReady()
            }
            .store(in: &cancellables)
    }
    
    func setGameStateManager(_ manager: GameStateManager?) {
        guard let manager = manager else {
            isSceneReady = false
            scene = nil
            gameStateManager = nil
            return
        }
        
        self.gameStateManager = manager
        
        if scene == nil {
            initializeScene()
        } else if isSceneReady {
            updateMapData()
        }
    }
    
    private func initializeScene() {
        guard let gameManager = gameStateManager else {
            isSceneReady = false
            return
        }
        
        let newScene = GameScene()
        newScene.gameDelegate = self
        newScene.size = CGSize(width: 1024, height: 768)
        newScene.scaleMode = .aspectFit
        
        let mapManager = MapManager(pois: gameManager.pointsOfInterest)
        newScene.setMapManager(mapManager)
        
        self.scene = newScene
    }
    
    private func handleSceneReady() {
        isSceneReady = true
        updateMapData()
    }
    
    var pointsOfInterest: [PointOfInterest] {
        return gameStateManager?.pointsOfInterest ?? []
    }
    
    var activePOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isOperational }
    }
    
    var capturedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isCaptured }
    }
    
    var destroyedPOIs: [PointOfInterest] {
        return pointsOfInterest.filter { $0.isDestroyed }
    }
    
    func focusOnPOI(_ poi: PointOfInterest) {
        scene?.focusOnPOI(poi, animated: true)
    }
    
    func updateMapData() {
        guard let gameManager = gameStateManager else { return }
        
        let mapManager = MapManager(pois: gameManager.pointsOfInterest)
        scene?.setMapManager(mapManager)
        scene?.updatePOIs()
        
        if let selected = selectedPOI {
            if let updatedPOI = gameManager.getPOI(withID: selected.id) {
                selectedPOI = updatedPOI
            } else {
                deselectPOI()
            }
        }
    }
    
    func updatePOI(_ poi: PointOfInterest) {
        scene?.updatePOI(with: poi.id)
        
        if selectedPOI?.id == poi.id {
            selectedPOI = poi
        }
    }
    
    func deselectPOI() {
        selectedPOI = nil
        showActionOverlay = false
    }
    
    func selectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        if let gameManager = gameStateManager,
           let currentPOI = gameManager.getPOI(withID: poi.id) {
            selectedPOI = currentPOI
        } else {
            selectedPOI = poi
        }
        
        overlayPosition = position
        showActionOverlay = true
    }
    
    func getPOI(withID id: UUID) -> PointOfInterest? {
        return gameStateManager?.getPOI(withID: id)
    }
    
    func getPOI(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return gameStateManager?.getPOI(at: position, tolerance: tolerance)
    }
    
    var mapStatistics: String {
        guard let gameManager = gameStateManager else {
            return "No game data"
        }
        
        let state = gameManager.exportGameState()
        let totalPOIs = state.totalPOIs
        let activePOIs = state.activePOIs.count
        let capturedPOIs = state.capturedPOIs.count
        let destroyedPOIs = state.destroyedPOIs.count
        let alertLevel = state.alertPercentage
        
        return "Total: \(totalPOIs) | Active: \(activePOIs) | Captured: \(capturedPOIs) | Destroyed: \(destroyedPOIs) | Alert: \(alertLevel)%"
    }
    
    var gameProgressSummary: String {
        guard let gameManager = gameStateManager else {
            return "No active game"
        }
        
        let state = gameManager.exportGameState()
        let progress = Int(state.completionPercentage * 100)
        return "Mission Progress: \(progress)%"
    }
    
    var currentResources: Resource {
        return gameStateManager?.currentResources ?? Resource.zero
    }
    
    var canPerformOperations: Bool {
        let resources = currentResources
        return resources.units > 0 && (resources.ammo > 0 || resources.food > 0)
    }
    
    var isGameActive: Bool {
        return gameStateManager?.isGameActive ?? false
    }
    
    var currentAlertLevel: Double {
        return gameStateManager?.currentAlertLevel ?? 0.0
    }
    
    var alertPercentage: Int {
        return Int(currentAlertLevel * 100)
    }
    
    func validateMapState() -> String? {
        guard let gameManager = gameStateManager else {
            return "No game state available"
        }
        
        let activePOIs = gameManager.pointsOfInterest.filter { $0.isOperational }
        
        if activePOIs.isEmpty {
            return "Victory condition met - all POIs captured/destroyed"
        }
        
        if gameManager.currentAlertLevel >= 1.0 {
            return "Defeat condition met - base discovered"
        }
        
        return nil
    }
    
    var debugInfo: String {
        guard let gameManager = gameStateManager else {
            return "No game state"
        }
        
        let state = gameManager.exportGameState()
        return """
        Game Status: \(state.status.displayName)
        POIs: \(state.activePOIs.count) active, \(state.capturedPOIs.count) captured, \(state.destroyedPOIs.count) destroyed
        Alert Level: \(state.alertPercentage)%
        Resources: \(state.resources.totalValue) total value
        Can Perform Operations: \(canPerformOperations)
        Scene Ready: \(isSceneReady)
        POI Count: \(pointsOfInterest.count)
        """
    }
    
    func forceRefresh() {
        guard isSceneReady else { return }
        updateMapData()
    }
    
    func cleanup() {
        scene = nil
        selectedPOI = nil
        showActionOverlay = false
        isSceneReady = false
        gameStateManager = nil
        cancellables.removeAll()
    }
}

extension GameSceneViewModel: GameSceneDelegate {
    func didSelectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        DispatchQueue.main.async {
            self.selectPOI(poi, at: position)
        }
    }
    
    func didDeselectPOI() {
        DispatchQueue.main.async {
            self.deselectPOI()
        }
    }
}
