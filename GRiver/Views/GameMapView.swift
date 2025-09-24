import SwiftUI
import SpriteKit

struct GameMapView: View {
    @EnvironmentObject var viewModel: GameSceneViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showOnboarding = false
    @State private var isFirstLaunch = true
    
    var body: some View {
        ZStack {
            if let scene = viewModel.scene {
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .onReceive(NotificationCenter.default.publisher(for: .poiSelected)) { notification in
                        if let userInfo = notification.userInfo,
                           let poi = userInfo["poi"] as? PointOfInterest,
                           let position = userInfo["position"] as? CGPoint {
                            handlePOISelected(poi, at: position)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .poiDeselected)) { _ in
                        handlePOIDeselected()
                    }
            } else {
                Color.black.ignoresSafeArea()
            }
            
            if !viewModel.isSceneReady {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading Tactical Map...")
                            .laborFont(16)
                    }
                }
            }
            
            if viewModel.isSceneReady {
                VStack {
                    mapTopBarControl
                    
                    Spacer()
                    
                    bottomOverlay
                }
            }
            
            // Onboarding View - shown only for new games
            if showOnboarding {
                VStack {
                    Spacer()
                    HStack {
                        OnboardingView(isVisible: $showOnboarding)
                        Spacer()
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 20)
            }
            
            if coordinator.showBaseOverlay {
                baseManagementOverlay
                    .zIndex(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            initializeScene()
            checkForNewGame()
        }
    }
    
    private func initializeScene() {
        guard coordinator.isGameActive else { return }
        
        if !viewModel.isSceneReady {
            viewModel.setGameStateManager(coordinator.gameStateManager)
        }
    }
    
    // Check if this is a new game and show onboarding if needed
    private func checkForNewGame() {
        // Only show onboarding for new games (when statistics are at initial values)
        if let gameState = coordinator.currentGameState {
            let isNewGame = gameState.statistics.operationsPerformed == 0 && 
                           gameState.statistics.poisCaptured == 0 && 
                           gameState.statistics.poisDestroyed == 0
            
            if isNewGame && isFirstLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showOnboarding = true
                        isFirstLaunch = false
                    }
                }
            }
        }
    }
    
    private var mapTopBarControl: some View {
        HStack(alignment: .top, spacing: 16) {
            Button {
                coordinator.navigateToMainMenu()
            } label: {
                Image(.squareButton)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(.homeIcon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
            }
            
            Spacer()
            
            resourcesSection
            
            Spacer()
            
            alarmSection
        }
        .padding()
    }
    
    private var resourcesSection: some View {
        HStack(spacing: 4) {
            let resources = coordinator.currentGameState?.resources ?? Resource.zero
            
            resourceCard1("\(resources.money)", .coin)
            resourceCard1("\(resources.units)", .units)
            resourceCard2("\(resources.ammo)", .ammo)
            resourceCard2("\(resources.food)", .food)
        }
    }
    
    private func resourceCard1(_ value: String, _ icon: ImageResource) -> some View {
        Image(icon)
            .resizable()
            .frame(width: 40, height: 40)
            .overlay(alignment: .bottom) {
                ZStack {
                    Image(.frame2)
                        .resizable()
                        .frame(width: 40, height: 20)
                    
                    Text(value)
                        .laborFont(10)
                }
                .offset(y: 12)
            }
    }
    
    private func resourceCard2(_ value: String, _ icon: ImageResource) -> some View {
        Image(.box)
            .resizable()
            .frame(width: 40, height: 40)
            .overlay {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12)
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    Image(.frame2)
                        .resizable()
                        .frame(width: 40, height: 20)
                    
                    Text(value)
                        .laborFont(10)
                }
                .offset(y: 12)
            }
    }
    
    private var alarmSection: some View {
        let alertLevel = coordinator.currentGameState?.alertPercentage ?? 0
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("ALARM")
                    .laborFont(14)
                
                Spacer()
                
                Text("\(alertLevel)%")
                    .laborFont(14)
            }
            
            alarmBar(alertLevel: alertLevel)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: 200)
    }
    
    private func alarmBar(alertLevel: Int) -> some View {
        let segmentCount = 20
        let filledSegments = Int(Double(alertLevel) / 100.0 * Double(segmentCount))
        
        return HStack(spacing: 2) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Rectangle()
                    .fill(segmentColor(for: index, total: segmentCount, filled: filledSegments))
                    .frame(width: 6, height: 20)
            }
        }
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    private func segmentColor(for index: Int, total: Int, filled: Int) -> Color {
        if index >= filled {
            return Color.gray.opacity(0.3)
        }
        
        let progress = Double(index) / Double(total)
        
        switch progress {
        case 0.0..<0.15:
            return Color(red: 0.0, green: 0.5, blue: 0.0) // Dark green
        case 0.15..<0.3:
            return Color(red: 0.0, green: 0.7, blue: 0.0) // Medium green
        case 0.3..<0.45:
            return Color(red: 0.2, green: 0.8, blue: 0.0) // Light green
        case 0.45..<0.55:
            return Color(red: 0.5, green: 0.8, blue: 0.0) // Yellow-green
        case 0.55..<0.65:
            return Color(red: 0.8, green: 0.8, blue: 0.0) // Yellow
        case 0.65..<0.75:
            return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        case 0.75..<0.85:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Red-orange
        case 0.85..<0.95:
            return Color(red: 1.0, green: 0.2, blue: 0.0) // Red
        default:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Bright red
        }
    }
    
    private var bottomOverlay: some View {
        Group {
            if let selectedPOI = viewModel.selectedPOI {
                selectedPOIInfo(selectedPOI)
                    .padding(.bottom, 20)
            } else {
                HStack {
                    Spacer()
                    
                    Button {
                        coordinator.showBaseManagement()
                    } label: {
                        Image(.rectangleButton)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 150)
                            .overlay {
                                Text("Warehouse")
                                    .laborFont(16)
                            }
                    }
                }
                .padding()
            }
        }
    }
    
    private func selectedPOIInfo(_ poi: PointOfInterest) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(poi.type.displayName)
                    .laborFont(14)
                
                Text("Status: \(poi.status.displayName)")
                    .laborFont(12 ,color: poi.isOperational ? .green : .red)
                
                Text("Defense: \(poi.totalDefense) | Units: \(poi.currentUnits)")
                    .laborFont(12)
                
                if poi.defenseBonus > 0 {
                    Text("Alert Bonus: +\(poi.defenseBonus)")
                        .laborFont(10)
                }
            }
            
            HStack(spacing: 14) {
                Button {
                    viewModel.focusOnPOI(poi)
                } label: {
                    VStack(spacing: 2) {
                        Image(.circleButton)
                            .resizable()
                            .frame(width: 35, height: 35)
                            .overlay {
                                Image(systemName: "eye")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                        
                        Text("Focus")
                            .laborFont(10)
                    }
                }
                
                if poi.isOperational {
                    Button {
                        selectPOIForAction(poi)
                    } label: {
                        Image(.rectangleButton)
                            .resizable()
                            .frame(width: 150, height: 50)
                            .overlay {
                                Text("Select")
                                    .laborFont(10)
                            }
                    }
                }
                
                Button {
                    viewModel.deselectPOI()
                } label: {
                    VStack(spacing: 2) {
                        Image(.circleButton)
                            .resizable()
                            .frame(width: 35, height: 35)
                            .overlay {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                        
                        Text("Close")
                            .laborFont(10)
                    }
                }
            }
        }
        .padding()
        .background(
            Image(.frame1)
                .resizable()
        )
    }
    
    private var baseManagementOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    coordinator.hideBaseManagement()
                }
            
            PlayerBaseView {
                coordinator.hideBaseManagement()
            }
            .environmentObject(coordinator.getBaseViewModel())
            .shadow(radius: 10)
        }
    }
    
    private func handlePOISelected(_ poi: PointOfInterest, at position: CGPoint) {
        viewModel.selectPOI(poi, at: position)
    }
    
    private func handlePOIDeselected() {
        viewModel.deselectPOI()
    }
    
    private func selectPOIForAction(_ poi: PointOfInterest) {
        let screenPosition = CGPoint(x: 400, y: 300)
        
        NotificationCenter.default.post(
            name: .requestActionOverlay,
            object: nil,
            userInfo: [
                "poi": poi,
                "position": screenPosition
            ]
        )
    }
}

extension Notification.Name {
    static let requestActionOverlay = Notification.Name("requestActionOverlay")
}

#Preview {
    GameMapView()
        .environmentObject(GameSceneViewModel())
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}
