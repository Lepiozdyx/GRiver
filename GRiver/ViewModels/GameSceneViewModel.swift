import Foundation
import Combine
import SpriteKit

// MARK: - Game Scene View Model
class GameSceneViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var selectedPOI: PointOfInterest?
    @Published var showActionOverlay: Bool = false
    @Published var overlayPosition: CGPoint = .zero
    
    private let mapManager: MapManager
    private var gameScene: GameScene?
    
    // MARK: - Initialization
    init() {
        self.mapManager = MapManager()
    }
    
    // MARK: - Scene Setup
    func createScene() -> GameScene {
        let scene = GameScene()
        scene.gameDelegate = self
        scene.setMapManager(mapManager)
        
        // Configure scene size for landscape
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .aspectFit
        
        self.gameScene = scene
        return scene
    }
    
    // MARK: - POI Access
    var pointsOfInterest: [PointOfInterest] {
        return mapManager.pointsOfInterest
    }
    
    var activePOIs: [PointOfInterest] {
        return mapManager.activePOIs
    }
    
    var capturedPOIs: [PointOfInterest] {
        return mapManager.capturedPOIs
    }
    
    var destroyedPOIs: [PointOfInterest] {
        return mapManager.destroyedPOIs
    }
    
    // MARK: - Map Control
    func focusOnPOI(_ poi: PointOfInterest) {
        gameScene?.focusOnPOI(poi, animated: true)
    }
    
    func resetCamera() {
        gameScene?.resetCameraPosition(animated: true)
    }
    
    func refreshMap() {
        gameScene?.updatePOIs()
    }
    
    // MARK: - POI Selection
    func deselectPOI() {
        selectedPOI = nil
        showActionOverlay = false
    }
    
    func selectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        selectedPOI = poi
        overlayPosition = position
        showActionOverlay = true
    }
    
    // MARK: - Debug Information
    var mapStatistics: String {
        let stats = mapManager.getMapStatistics()
        return "Total POIs: \(stats.totalPOIs), Active: \(stats.activePOIs), Captured: \(stats.capturedPOIs), Destroyed: \(stats.destroyedPOIs)"
    }
    
    // MARK: - Testing Methods
    func testCapturePOI(_ poi: PointOfInterest) {
        let success = mapManager.capturePOI(with: poi.id)
        if success {
            gameScene?.updatePOI(with: poi.id)
            print("POI captured: \(poi.type.displayName)")
        }
    }
    
    func testDestroyPOI(_ poi: PointOfInterest) {
        let success = mapManager.destroyPOI(with: poi.id)
        if success {
            gameScene?.updatePOI(with: poi.id) 
            print("POI destroyed: \(poi.type.displayName)")
        }
    }
    
    func resetMapToDefault() {
        mapManager.resetMap()
        refreshMap()
        deselectPOI()
    }
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
