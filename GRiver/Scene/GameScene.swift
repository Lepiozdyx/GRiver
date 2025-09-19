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
    
    // Selection state
    private var selectedPOINode: POINode?
    private var lastSelectedPOI: PointOfInterest?
    
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
        
        // Listen for external POI updates
        setupNotificationObservers()
    }
    
    private func setupScene() {
        backgroundColor = SKColor.black
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
        initialCameraScale = 1.0
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(color: SKColor.systemGray6, size: mapSize)
        background.position = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        background.zPosition = -1
        addChild(background)
        backgroundNode = background
        
        // Add grid pattern for tactical feel
        addGridPattern()
    }
    
    private func addGridPattern() {
        let gridSize: CGFloat = 50
        let lineWidth: CGFloat = 0.5
        
        // Vertical lines
        for x in stride(from: 0, through: mapSize.width, by: gridSize) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: mapSize.height))
            line.path = path
            line.strokeColor = SKColor.gray.withAlphaComponent(0.3)
            line.lineWidth = lineWidth
            line.zPosition = -0.5
            addChild(line)
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: mapSize.height, by: gridSize) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: mapSize.width, y: y))
            line.path = path
            line.strokeColor = SKColor.gray.withAlphaComponent(0.3)
            line.lineWidth = lineWidth
            line.zPosition = -0.5
            addChild(line)
        }
    }
    
    private func setupPOIContainer() {
        let container = SKNode()
        container.zPosition = 1
        addChild(container)
        poiContainer = container
    }
    
    private func setupGestureRecognizers() {
        guard let view = view else { return }
        
        // Clear existing gesture recognizers
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
        
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePOIUpdateNotification(_:)),
            name: .poiUpdated,
            object: nil
        )
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
            poiNode.name = "poi_\(poi.id.uuidString)"
            container.addChild(poiNode)
            poiNodes[poi.id] = poiNode
        }
        
        // Update selection if needed
        updateSelectedPOINode()
    }
    
    func updatePOI(with id: UUID) {
        guard let mapManager = mapManager,
              let poi = mapManager.poi(withID: id),
              let poiNode = poiNodes[id] else { return }
        
        poiNode.updatePOI(poi)
        
        // Update last selected POI if it matches
        if lastSelectedPOI?.id == id {
            lastSelectedPOI = poi
        }
    }
    
    private func updateSelectedPOINode() {
        // Clear current selection visual
        selectedPOINode?.setSelected(false)
        selectedPOINode = nil
        
        // Update selection if we have a selected POI
        if let selectedPOI = lastSelectedPOI,
           let poiNode = poiNodes[selectedPOI.id] {
            selectedPOINode = poiNode
            poiNode.setSelected(true)
        }
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
            selectPOI(tappedPOI, at: sceneLocation)
        } else {
            deselectPOI()
        }
    }
    
    private func findPOI(at position: CGPoint) -> PointOfInterest? {
        guard let mapManager = mapManager else { return nil }
        
        // Find POI within tolerance
        let tolerance: CGFloat = 40.0
        return mapManager.poi(at: position, tolerance: tolerance)
    }
    
    private func selectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        lastSelectedPOI = poi
        updateSelectedPOINode()
        
        // Notify delegate
        gameDelegate?.didSelectPOI(poi, at: position)
        
        // Send notification for coordinator integration
        NotificationCenter.default.post(
            name: .poiSelected,
            object: self,
            userInfo: [
                "poi": poi,
                "position": position
            ]
        )
    }
    
    private func deselectPOI() {
        lastSelectedPOI = nil
        updateSelectedPOINode()
        
        // Notify delegate
        gameDelegate?.didDeselectPOI()
        
        // Send notification
        NotificationCenter.default.post(name: .poiDeselected, object: self)
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
        
        let targetPosition = constrainCameraPosition(poi.position)
        
        if animated {
            let moveAction = SKAction.move(to: targetPosition, duration: 0.5)
            moveAction.timingMode = .easeInEaseOut
            camera.run(moveAction)
        } else {
            camera.position = targetPosition
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
    
    // MARK: - Notification Handlers
    @objc private func handlePOIUpdateNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let poiID = userInfo["poiID"] as? UUID else { return }
        
        DispatchQueue.main.async {
            self.updatePOI(with: poiID)
        }
    }
    
    // MARK: - Scene Update
    override func update(_ currentTime: TimeInterval) {
        // Update POI visual states if needed
        updatePOIVisuals()
    }
    
    private func updatePOIVisuals() {
        for poiNode in poiNodes.values {
            poiNode.updateVisualState()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        view?.gestureRecognizers?.forEach { view?.removeGestureRecognizer($0) }
    }
}

// MARK: - POI Node
class POINode: SKSpriteNode {
    private var poi: PointOfInterest
    private let typeLabel: SKLabelNode
    private let statusIndicator: SKShapeNode
    private let selectionRing: SKShapeNode
    
    init(poi: PointOfInterest) {
        self.poi = poi
        
        // Create type label
        typeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        typeLabel.fontSize = 10
        typeLabel.fontColor = .white
        typeLabel.text = poi.type.displayName.prefix(3).uppercased()
        typeLabel.position = CGPoint(x: 0, y: -30)
        typeLabel.zPosition = 2
        
        // Create status indicator
        statusIndicator = SKShapeNode(circleOfRadius: 4)
        statusIndicator.position = CGPoint(x: 12, y: 12)
        statusIndicator.zPosition = 2
        
        // Create selection ring
        selectionRing = SKShapeNode(circleOfRadius: 25)
        selectionRing.strokeColor = .cyan
        selectionRing.lineWidth = 2
        selectionRing.fillColor = .clear
        selectionRing.zPosition = 0
        selectionRing.isHidden = true
        
        let texture = SKTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: 30, height: 30))
        
        setupAppearance()
        addChild(typeLabel)
        addChild(statusIndicator)
        addChild(selectionRing)
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
        self.poi = newPOI
        updateStatusIndicator()
        updateTypeLabel()
    }
    
    func updateVisualState() {
        updateStatusIndicator()
    }
    
    func setSelected(_ selected: Bool) {
        selectionRing.isHidden = !selected
        
        if selected {
            // Add pulsing animation
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            selectionRing.run(SKAction.repeatForever(pulseAction))
        } else {
            selectionRing.removeAllActions()
        }
    }
    
    private func updateStatusIndicator() {
        switch poi.status {
        case .active:
            statusIndicator.fillColor = .green
            statusIndicator.strokeColor = .green
        case .captured:
            statusIndicator.fillColor = .blue
            statusIndicator.strokeColor = .blue
        case .destroyed:
            statusIndicator.fillColor = .black
            statusIndicator.strokeColor = .black
        }
    }
    
    private func updateTypeLabel() {
        typeLabel.text = poi.type.displayName.prefix(3).uppercased()
        
        // Update text color based on status
        switch poi.status {
        case .active:
            typeLabel.fontColor = .white
        case .captured:
            typeLabel.fontColor = .cyan
        case .destroyed:
            typeLabel.fontColor = .gray
        }
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let poiUpdated = Notification.Name("poiUpdated")
}
