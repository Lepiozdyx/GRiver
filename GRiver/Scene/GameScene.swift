import SpriteKit
import SwiftUI

// MARK: - Game Scene Delegate
protocol GameSceneDelegate: AnyObject {
    func didSelectPOI(_ poi: PointOfInterest, at position: CGPoint)
    func didDeselectPOI()
}

// MARK: - Game Scene
class GameScene: SKScene {
    
    // MARK: - Properties
    weak var gameDelegate: GameSceneDelegate?
    private var mapManager: MapManager?
    
    // Scene nodes
    private var backgroundNode: SKSpriteNode?
    private var poiContainer: SKNode?
    private var poiNodes: [UUID: POINode] = [:]
    
    // Camera and gesture handling
    private var mapCamera: SKCameraNode?
    private var lastPanPoint: CGPoint = .zero
    private var initialCameraScale: CGFloat = 1.0
    
    // Map boundaries and limits
    private let mapSize = CGSize(width: 1024, height: 768)
    private let minZoomScale: CGFloat = 0.5
    private let maxZoomScale: CGFloat = 2.0
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        setupCamera()
        setupBackground()
        setupPOIContainer()
        setupGestureRecognizers()
    }
    
    private func setupScene() {
        backgroundColor = SKColor.systemBackground
        scaleMode = .aspectFit
    }
    
    private func setupCamera() {
        let camera = SKCameraNode()
        camera.setScale(1.0)
        addChild(camera)
        self.camera = camera
        self.mapCamera = camera
        
        // Center camera on map
        camera.position = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        initialCameraScale = 1.0 // Set directly instead of using camera.xScale
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(color: SKColor.systemGray5, size: mapSize)
        background.position = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        background.zPosition = -1
        addChild(background)
        backgroundNode = background
    }
    
    private func setupPOIContainer() {
        let container = SKNode()
        container.zPosition = 1
        addChild(container)
        poiContainer = container
    }
    
    private func setupGestureRecognizers() {
        guard let view = view else { return }
        
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Map Manager Integration
    func setMapManager(_ manager: MapManager) {
        mapManager = manager
        updatePOIs()
    }
    
    func updatePOIs() {
        guard let mapManager = mapManager, let container = poiContainer else { return }
        
        // Remove old POI nodes
        poiNodes.values.forEach { $0.removeFromParent() }
        poiNodes.removeAll()
        
        // Create new POI nodes
        for poi in mapManager.pointsOfInterest {
            let poiNode = POINode(poi: poi)
            poiNode.position = poi.position
            container.addChild(poiNode)
            poiNodes[poi.id] = poiNode
        }
    }
    
    func updatePOI(with id: UUID) {
        guard let mapManager = mapManager,
              let poi = mapManager.poi(withID: id),
              let poiNode = poiNodes[id] else { return }
        
        poiNode.updatePOI(poi)
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = view, let camera = mapCamera else { return }
        
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            lastPanPoint = camera.position
            
        case .changed:
            let newPosition = CGPoint(
                x: lastPanPoint.x - translation.x * camera.xScale,
                y: lastPanPoint.y + translation.y * camera.yScale
            )
            camera.position = constrainCameraPosition(newPosition)
            
        default:
            break
        }
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = mapCamera else { return }
        
        switch gesture.state {
        case .changed:
            let newScale = camera.xScale / gesture.scale
            let constrainedScale = max(minZoomScale, min(maxZoomScale, newScale))
            
            camera.setScale(constrainedScale)
            camera.position = constrainCameraPosition(camera.position)
            
            gesture.scale = 1.0
            
        default:
            break
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let view = view else { return }
        
        let location = gesture.location(in: view)
        let sceneLocation = convertPoint(fromView: location)
        
        // Check if tap hit any POI
        if let tappedPOI = findPOI(at: sceneLocation) {
            gameDelegate?.didSelectPOI(tappedPOI, at: sceneLocation)
        } else {
            gameDelegate?.didDeselectPOI()
        }
    }
    
    private func findPOI(at position: CGPoint) -> PointOfInterest? {
        guard let mapManager = mapManager else { return nil }
        
        return mapManager.poi(at: position, tolerance: 30.0)
    }
    
    private func constrainCameraPosition(_ position: CGPoint) -> CGPoint {
        guard let camera = mapCamera else { return position }
        
        let scale = camera.xScale
        let viewSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Calculate boundaries
        let minX = viewSize.width / 2
        let maxX = mapSize.width - viewSize.width / 2
        let minY = viewSize.height / 2
        let maxY = mapSize.height - viewSize.height / 2
        
        return CGPoint(
            x: max(minX, min(maxX, position.x)),
            y: max(minY, min(maxY, position.y))
        )
    }
    
    // MARK: - Camera Control
    func focusOnPOI(_ poi: PointOfInterest, animated: Bool = true) {
        guard let camera = mapCamera else { return }
        
        let targetPosition = poi.position
        
        if animated {
            let moveAction = SKAction.move(to: targetPosition, duration: 0.5)
            moveAction.timingMode = .easeInEaseOut
            camera.run(moveAction)
        } else {
            camera.position = constrainCameraPosition(targetPosition)
        }
    }
    
    func resetCameraPosition(animated: Bool = true) {
        guard let camera = mapCamera else { return }
        
        let centerPosition = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        
        if animated {
            let moveAction = SKAction.move(to: centerPosition, duration: 0.5)
            let scaleAction = SKAction.scale(to: initialCameraScale, duration: 0.5)
            let groupAction = SKAction.group([moveAction, scaleAction])
            groupAction.timingMode = .easeInEaseOut
            camera.run(groupAction)
        } else {
            camera.position = centerPosition
            camera.setScale(initialCameraScale)
        }
    }
    
    // MARK: - Scene Update
    override func update(_ currentTime: TimeInterval) {
        // Update POI visual states if needed
        updatePOIVisuals()
    }
    
    private func updatePOIVisuals() {
        guard let mapManager = mapManager else { return }
        
        for poi in mapManager.pointsOfInterest {
            if let poiNode = poiNodes[poi.id] {
                poiNode.updateVisualState()
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        view?.gestureRecognizers?.forEach { view?.removeGestureRecognizer($0) }
    }
}

// MARK: - POI Node
class POINode: SKSpriteNode {
    private var poi: PointOfInterest // Changed from let to var
    private let typeLabel: SKLabelNode
    private let statusIndicator: SKShapeNode
    
    init(poi: PointOfInterest) {
        self.poi = poi
        
        // Create type label
        typeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        typeLabel.fontSize = 12
        typeLabel.fontColor = .white
        typeLabel.text = poi.type.displayName
        typeLabel.position = CGPoint(x: 0, y: -25)
        typeLabel.zPosition = 2
        
        // Create status indicator
        statusIndicator = SKShapeNode(circleOfRadius: 5)
        statusIndicator.position = CGPoint(x: 15, y: 15)
        statusIndicator.zPosition = 2
        
        let texture = SKTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: 40, height: 40))
        
        setupAppearance()
        addChild(typeLabel)
        addChild(statusIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        // Set POI appearance based on type
        switch poi.type {
        case .base:
            color = .red
        case .village:
            color = .brown
        case .warehouse:
            color = .gray
        case .station:
            color = .blue
        case .factory:
            color = .purple
        }
        
        // Set status indicator color
        updateStatusIndicator()
    }
    
    func updatePOI(_ newPOI: PointOfInterest) {
        // Update internal POI reference and visual state
        self.poi = newPOI
        updateStatusIndicator()
    }
    
    func updateVisualState() {
        updateStatusIndicator()
    }
    
    private func updateStatusIndicator() {
        switch poi.status {
        case .active:
            statusIndicator.fillColor = .green
        case .captured:
            statusIndicator.fillColor = .blue
        case .destroyed:
            statusIndicator.fillColor = .black
        }
        
        statusIndicator.strokeColor = statusIndicator.fillColor
    }
}
