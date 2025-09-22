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
    
    private let minZoomScale: CGFloat = 0.5
    private let maxZoomScale: CGFloat = 2.0
    
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
        camera.setScale(1.0)
        addChild(camera)
        self.camera = camera
        self.mapCamera = camera
        
        camera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        initialCameraScale = 1.0
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(color: SKColor.systemGray6, size: size)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        addChild(background)
        backgroundNode = background
        
        addGridPattern()
    }
    
    private func addGridPattern() {
        let gridSize: CGFloat = 50
        let lineWidth: CGFloat = 0.5
        
        for x in stride(from: 0, through: size.width, by: gridSize) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            line.path = path
            line.strokeColor = SKColor.gray.withAlphaComponent(0.3)
            line.lineWidth = lineWidth
            line.zPosition = -0.5
            addChild(line)
        }
        
        for y in stride(from: 0, through: size.height, by: gridSize) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
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
        for touch in touches {
            activeTouches[touch] = touch.location(in: self)
        }
        
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
            let delta = CGPoint(
                x: currentPosition.x - lastPosition.x,
                y: currentPosition.y - lastPosition.y
            )
            
            let newPosition = CGPoint(
                x: camera.position.x - delta.x,
                y: camera.position.y - delta.y
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
        
        let scaleChange = initialDistance / currentDistance
        let newScale = initialScale * scaleChange
        let constrainedScale = max(minZoomScale, min(maxZoomScale, newScale))
        
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
        
        let tolerance: CGFloat = 40.0
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
        let viewSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let minX = viewSize.width / 2
        let maxX = size.width - viewSize.width / 2
        let minY = viewSize.height / 2
        let maxY = size.height - viewSize.height / 2
        
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
        
        let centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        
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
    private let statusIndicator: SKShapeNode
    private let selectionRing: SKShapeNode
    
    init(poi: PointOfInterest) {
        self.poi = poi
        
        typeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        typeLabel.fontSize = 10
        typeLabel.fontColor = .white
        typeLabel.text = poi.type.displayName.prefix(3).uppercased()
        typeLabel.position = CGPoint(x: 0, y: -30)
        typeLabel.zPosition = 2
        
        statusIndicator = SKShapeNode(circleOfRadius: 4)
        statusIndicator.position = CGPoint(x: 12, y: 12)
        statusIndicator.zPosition = 2
        
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
