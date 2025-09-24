import SpriteKit
import SwiftUI

protocol GameSceneDelegate: AnyObject {
    func didSelectPOI(_ poi: PointOfInterest, at position: CGPoint)
    func didDeselectPOI()
}

class GameScene: SKScene {
    
    weak var gameDelegate: GameSceneDelegate?
    private var mapManager: MapManager?
    
    private var backgroundNode: SKSpriteNode?
    private var poiContainer: SKNode?
    private var poiNodes: [UUID: POINode] = [:]
    
    private var selectedPOINode: POINode?
    private var lastSelectedPOI: PointOfInterest?
    
    private var mapCamera: SKCameraNode?
    private var initialCameraScale: CGFloat = 1.0
    
    private var minZoomScale: CGFloat = 0.5
    private var maxZoomScale: CGFloat = 2.0
    
    private var mapSize: CGSize = .zero
    
    private var activeTouches: [UITouch: CGPoint] = [:]
    private var touchStartPositions: [UITouch: CGPoint] = [:]
    private var lastPanPosition: CGPoint?
    private var initialPinchDistance: CGFloat?
    private var initialPinchScale: CGFloat?
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        
        size = view.bounds.size
        scaleMode = .resizeFill
        
        setupScene()
        setupCamera()
        setupBackground()
        setupPOIContainer()
        setupNotificationObservers()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sceneDidBecomeReady, object: self)
        }
    }
    
    private func setupScene() {
        backgroundColor = SKColor.black
    }
    
    private func setupCamera() {
        let camera = SKCameraNode()
        addChild(camera)
        self.camera = camera
        self.mapCamera = camera
    }
    
    private func setupBackground() {
        let mapTexture = SKTexture(imageNamed: "map1")
        let background = SKSpriteNode(texture: mapTexture)
        
        let imageSize = mapTexture.size()
        let sceneSize = size
        
        let scaleX = sceneSize.width / imageSize.width
        let scaleY = sceneSize.height / imageSize.height
        let scale = max(scaleX, scaleY)
        
        mapSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        background.size = mapSize
        background.position = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        background.zPosition = -1
        
        addChild(background)
        backgroundNode = background
        
        calculateZoomLimits()
        setupInitialCameraPosition()
    }
    
    private func calculateZoomLimits() {
        let scaleX = size.width / mapSize.width
        let scaleY = size.height / mapSize.height
        let minScale = max(scaleX, scaleY)
        
        minZoomScale = 0.5
        maxZoomScale = minScale
        initialCameraScale = maxZoomScale
    }
    
    private func setupInitialCameraPosition() {
        guard let camera = mapCamera else { return }
        
        camera.setScale(initialCameraScale)
        
        let viewWidth = size.width * initialCameraScale
        let viewHeight = size.height * initialCameraScale
        
        let initialX = viewWidth / 2
        let initialY = mapSize.height - viewHeight / 2
        
        camera.position = CGPoint(x: initialX, y: initialY)
    }
    
    private func setupPOIContainer() {
        let container = SKNode()
        container.zPosition = 1
        addChild(container)
        poiContainer = container
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePOIUpdateNotification(_:)),
            name: .poiUpdated,
            object: nil
        )
    }
    
    func setMapManager(_ manager: MapManager) {
        mapManager = manager
        updatePOIs()
    }
    
    func updatePOIs() {
        guard let mapManager = mapManager, let container = poiContainer else { return }
        
        poiNodes.values.forEach { $0.removeFromParent() }
        poiNodes.removeAll()
        
        for poi in mapManager.pointsOfInterest {
            let poiNode = POINode(poi: poi)
            poiNode.position = poi.position
            poiNode.name = "poi_\(poi.id.uuidString)"
            container.addChild(poiNode)
            poiNodes[poi.id] = poiNode
        }
        
        updateSelectedPOINode()
    }
    
    func updatePOI(with id: UUID) {
        guard let mapManager = mapManager,
              let poi = mapManager.poi(withID: id),
              let poiNode = poiNodes[id] else { return }
        
        poiNode.updatePOI(poi)
        
        if lastSelectedPOI?.id == id {
            lastSelectedPOI = poi
        }
    }
    
    private func updateSelectedPOINode() {
        selectedPOINode?.setSelected(false)
        selectedPOINode = nil
        
        if let selectedPOI = lastSelectedPOI,
           let poiNode = poiNodes[selectedPOI.id] {
            selectedPOINode = poiNode
            poiNode.setSelected(true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            activeTouches[touch] = location
            touchStartPositions[touch] = location
        }
        
        if activeTouches.count == 1 {
            lastPanPosition = activeTouches.values.first
            initialPinchDistance = nil
            initialPinchScale = nil
        } else if activeTouches.count == 2 {
            let locations = Array(activeTouches.values)
            initialPinchDistance = distance(from: locations[0], to: locations[1])
            initialPinchScale = mapCamera?.xScale
            lastPanPosition = nil
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Update active touches first
        for touch in touches {
            activeTouches[touch] = touch.location(in: self)
        }
        
        // Handle gestures based on current touch count
        if activeTouches.count == 2 {
            handlePinch()
        } else if activeTouches.count == 1 {
            handlePan()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let startPosition = touchStartPositions[touch],
               let currentPosition = activeTouches[touch] {
                let distance = hypot(currentPosition.x - startPosition.x, currentPosition.y - startPosition.y)
                
                if distance < 10 && activeTouches.count == 1 {
                    handleTap(at: currentPosition)
                }
            }
            
            activeTouches.removeValue(forKey: touch)
            touchStartPositions.removeValue(forKey: touch)
        }
        
        if activeTouches.count == 1 {
            lastPanPosition = activeTouches.values.first
            initialPinchDistance = nil
            initialPinchScale = nil
        } else if activeTouches.count == 2 {
            let locations = Array(activeTouches.values)
            initialPinchDistance = distance(from: locations[0], to: locations[1])
            initialPinchScale = mapCamera?.xScale
            lastPanPosition = nil
        } else {
            lastPanPosition = nil
            initialPinchDistance = nil
            initialPinchScale = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.removeValue(forKey: touch)
            touchStartPositions.removeValue(forKey: touch)
        }
        
        if activeTouches.isEmpty {
            lastPanPosition = nil
            initialPinchDistance = nil
            initialPinchScale = nil
        }
    }
    
    private func handleTap(at location: CGPoint) {
        if let tappedPOI = findPOI(at: location) {
            selectPOI(tappedPOI, at: location)
        } else {
            deselectPOI()
        }
    }
    
    private func handlePan() {
        guard let camera = mapCamera,
              activeTouches.count == 1,
              let currentPosition = activeTouches.values.first else { return }
        
        if let lastPosition = lastPanPosition {
            let deltaX = (currentPosition.x - lastPosition.x) * camera.xScale
            let deltaY = (currentPosition.y - lastPosition.y) * camera.xScale
            
            let newPosition = CGPoint(
                x: camera.position.x - deltaX,
                y: camera.position.y - deltaY
            )
            
            camera.position = constrainCameraPosition(newPosition)
        }
        
        lastPanPosition = currentPosition
    }
    
    private func handlePinch() {
        guard activeTouches.count == 2,
              let camera = mapCamera,
              let initialDistance = initialPinchDistance,
              let initialScale = initialPinchScale else { return }
        
        let locations = Array(activeTouches.values)
        let currentDistance = distance(from: locations[0], to: locations[1])
        
        // Fixed scale calculation
        let scaleChange = currentDistance / initialDistance
        let newScale = initialScale * scaleChange
        let constrainedScale = max(minZoomScale, min(maxZoomScale, newScale))
        
        // Single camera update
        camera.setScale(constrainedScale)
        camera.position = constrainCameraPosition(camera.position)
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func findPOI(at position: CGPoint) -> PointOfInterest? {
        guard let mapManager = mapManager else { return nil }
        
        // Use dynamic tolerance based on the largest POI size
        let tolerance: CGFloat = 50.0 // Increased tolerance for larger assets
        return mapManager.poi(at: position, tolerance: tolerance)
    }
    
    private func selectPOI(_ poi: PointOfInterest, at position: CGPoint) {
        lastSelectedPOI = poi
        updateSelectedPOINode()
        
        gameDelegate?.didSelectPOI(poi, at: position)
        
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
        
        gameDelegate?.didDeselectPOI()
        
        NotificationCenter.default.post(name: .poiDeselected, object: self)
    }
    
    private func constrainCameraPosition(_ position: CGPoint) -> CGPoint {
        guard let camera = mapCamera else { return position }
        
        let scale = camera.xScale
        let viewWidth = size.width * scale
        let viewHeight = size.height * scale
        
        let minX = viewWidth / 2
        let maxX = mapSize.width - viewWidth / 2
        let minY = viewHeight / 2
        let maxY = mapSize.height - viewHeight / 2
        
        return CGPoint(
            x: max(minX, min(maxX, position.x)),
            y: max(minY, min(maxY, position.y))
        )
    }
    
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
        
        camera.setScale(initialCameraScale)
        
        let viewWidth = size.width * initialCameraScale
        let viewHeight = size.height * initialCameraScale
        
        let initialX = viewWidth / 2
        let initialY = mapSize.height - viewHeight / 2
        
        let centerPosition = CGPoint(x: initialX, y: initialY)
        
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
    
    @objc private func handlePOIUpdateNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let poiID = userInfo["poiID"] as? UUID else { return }
        
        DispatchQueue.main.async {
            self.updatePOI(with: poiID)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        updatePOIVisuals()
    }
    
    private func updatePOIVisuals() {
        for poiNode in poiNodes.values {
            poiNode.updateVisualState()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class POINode: SKSpriteNode {
    private var poi: PointOfInterest
    private let typeLabel: SKLabelNode
    private let statusIndicator: SKSpriteNode
    private var selectionRing: SKShapeNode
    
    init(poi: PointOfInterest) {
        self.poi = poi
        
        typeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        typeLabel.fontSize = 10
        typeLabel.fontColor = .white
        typeLabel.text = poi.type.displayName.prefix(3).uppercased()
        typeLabel.position = CGPoint(x: 0, y: -poi.type.size.height/2 - 15)
        typeLabel.zPosition = 2
        
        // Create status indicator with assets instead of shapes
        statusIndicator = SKSpriteNode()
        statusIndicator.size = CGSize(width: 15, height: 15)
        statusIndicator.position = CGPoint(x: poi.type.size.width/2 - 8, y: poi.type.size.height/2 - 8)
        statusIndicator.zPosition = 2
        
        let ringRadius = max(poi.type.size.width, poi.type.size.height) / 2 + 5
        selectionRing = SKShapeNode(circleOfRadius: ringRadius)
        selectionRing.strokeColor = .cyan
        selectionRing.lineWidth = 2
        selectionRing.fillColor = .clear
        selectionRing.zPosition = 0
        selectionRing.isHidden = true
        
        // Load the texture for this POI type
        let texture = SKTexture(imageNamed: poi.type.imageName)
        super.init(texture: texture, color: .clear, size: poi.type.size)
        
        addChild(typeLabel)
        addChild(statusIndicator)
        addChild(selectionRing)
        
        updateStatusIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateStatusIndicator() {
        switch poi.status {
        case .active:
            // Use enemyUnits asset for non-player controlled POIs
            statusIndicator.texture = SKTexture(imageNamed: "enemyUnits")
        case .captured:
            // Use units asset for player-controlled POIs
            statusIndicator.texture = SKTexture(imageNamed: "units")
        case .destroyed:
            // Use fire asset for destroyed POIs
            statusIndicator.texture = SKTexture(imageNamed: "fire")
        }
    }
    
    func updatePOI(_ newPOI: PointOfInterest) {
        self.poi = newPOI
        
        // Update texture and size if POI type changed
        let newTexture = SKTexture(imageNamed: newPOI.type.imageName)
        self.texture = newTexture
        self.size = newPOI.type.size
        
        // Update label and status indicator positions based on new size
        typeLabel.position = CGPoint(x: 0, y: -newPOI.type.size.height/2 - 15)
        statusIndicator.position = CGPoint(x: newPOI.type.size.width/2 - 8, y: newPOI.type.size.height/2 - 8)
        
        // Update selection ring radius
        let ringRadius = max(newPOI.type.size.width, newPOI.type.size.height) / 2 + 5
        selectionRing.removeFromParent()
        let newSelectionRing = SKShapeNode(circleOfRadius: ringRadius)
        newSelectionRing.strokeColor = .cyan
        newSelectionRing.lineWidth = 2
        newSelectionRing.fillColor = .clear
        newSelectionRing.zPosition = 0
        newSelectionRing.isHidden = true
        addChild(newSelectionRing)
        selectionRing = newSelectionRing
        
        updateStatusIndicator()
        updateTypeLabel()
    }
    
    func updateVisualState() {
        updateStatusIndicator()
    }
    
    func setSelected(_ selected: Bool) {
        selectionRing.isHidden = !selected
        
        if selected {
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            selectionRing.run(SKAction.repeatForever(pulseAction))
        } else {
            selectionRing.removeAllActions()
        }
    }
    
    private func updateTypeLabel() {
        typeLabel.text = poi.type.displayName.prefix(3).uppercased()
        
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

extension Notification.Name {
    static let poiUpdated = Notification.Name("poiUpdated")
    static let sceneDidBecomeReady = Notification.Name("sceneDidBecomeReady")
}
