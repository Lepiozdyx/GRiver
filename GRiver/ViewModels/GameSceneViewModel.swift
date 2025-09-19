import Foundation
import Combine
import SpriteKit

// MARK: - Game Scene View Model
class GameSceneViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var selectedPOI: PointOfInterest?
    @Published var showActionOverlay: Bool = false
    @Published var overlayPosition: CGPoint = .zero
    
    private var gameStateManager: GameStateManager?
    private var gameScene: GameScene?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Default initialization for cases where no GameStateManager is provided yet
    }
    
    convenience init(gameStateManager: GameStateManager?) {
        self.init()
        self.gameStateManager = gameStateManager
    }
    
    // MARK: - GameStateManager Integration
    func setGameStateManager(_ manager: GameStateManager) {
        self.gameStateManager = manager
        refreshMap()
    }
    
    // MARK: - Scene Setup
    func createScene() -> GameScene {
        let scene = GameScene()
        scene.gameDelegate = self
        
        // Set up scene with current POI data
        if let gameManager = gameStateManager {
            let mapManager = MapManager(pois: gameManager.pointsOfInterest)
            scene.setMapManager(mapManager)
        } else {
            // Fallback to default POIs for scene creation
            let mapManager = MapManager()
            scene.setMapManager(mapManager)
        }
        
        // Configure scene size for landscape
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .aspectFit
        
        self.gameScene = scene
        return scene
    }
    
    // MARK: - POI Access
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
    
    // MARK: - Map Control
    func focusOnPOI(_ poi: PointOfInterest) {
        gameScene?.focusOnPOI(poi, animated: true)
    }
    
    func resetCamera() {
        gameScene?.resetCameraPosition(animated: true)
    }
    
    func refreshMap() {
        guard let gameManager = gameStateManager else { return }
        
        // Update scene with latest POI data
        let mapManager = MapManager(pois: gameManager.pointsOfInterest)
        gameScene?.setMapManager(mapManager)
        gameScene?.updatePOIs()
        
        // Clear selection if selected POI no longer exists or is not operational
        if let selected = selectedPOI {
            if let updatedPOI = gameManager.getPOI(withID: selected.id) {
                selectedPOI = updatedPOI
            } else {
                deselectPOI()
            }
        }
    }
    
    func updatePOI(_ poi: PointOfInterest) {
        gameScene?.updatePOI(with: poi.id)
        
        // Update selected POI if it matches
        if selectedPOI?.id == poi.id {
            selectedPOI = poi
        }
    }
    
    // MARK: - POI Selection
    func deselectPOI() {
        selectedPOI = nil
        showActionOverlay = false
    }
    
    func selectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        // Ensure we have the latest POI data from game state
        if let gameManager = gameStateManager,
           let currentPOI = gameManager.getPOI(withID: poi.id) {
            selectedPOI = currentPOI
        } else {
            selectedPOI = poi
        }
        
        overlayPosition = position
        showActionOverlay = true
    }
    
    // MARK: - Game State Queries
    func getPOI(withID id: UUID) -> PointOfInterest? {
        return gameStateManager?.getPOI(withID: id)
    }
    
    func getPOI(at position: CGPoint, tolerance: CGFloat = 50.0) -> PointOfInterest? {
        return gameStateManager?.getPOI(at: position, tolerance: tolerance)
    }
    
    // MARK: - Map Statistics
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
    
    // MARK: - Resource Information
    var currentResources: Resource {
        return gameStateManager?.currentResources ?? Resource.zero
    }
    
    var canPerformOperations: Bool {
        let resources = currentResources
        return resources.units > 0 && (resources.ammo > 0 || resources.food > 0)
    }
    
    // MARK: - Game Status
    var isGameActive: Bool {
        return gameStateManager?.isGameActive ?? false
    }
    
    var currentAlertLevel: Double {
        return gameStateManager?.currentAlertLevel ?? 0.0
    }
    
    var alertPercentage: Int {
        return Int(currentAlertLevel * 100)
    }
    
    // MARK: - Map Validation
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
    
    // MARK: - Debug Information
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
        """
    }
    
    // MARK: - Reset and Cleanup
    func resetMapToDefault() {
        guard let gameManager = gameStateManager else { return }
        
        // Reset game state (this should reset POIs to default)
        gameManager.resetGame()
        
        // Refresh the map display
        refreshMap()
        deselectPOI()
    }
    
    func cleanup() {
        gameScene = nil
        selectedPOI = nil
        showActionOverlay = false
        cancellables.removeAll()
    }
    
    // MARK: - Deprecated Test Methods (removed)
    // These methods are no longer needed as operations are handled through the action overlay system
    // and game state manager
}

// MARK: - Game Scene Delegate
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
