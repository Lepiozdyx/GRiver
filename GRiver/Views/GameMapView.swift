import SwiftUI
import SpriteKit

struct GameMapView: View {
    @EnvironmentObject var viewModel: GameSceneViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
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
        }
    }
    
    private func initializeScene() {
        guard coordinator.isGameActive else { return }
        
        if !viewModel.isSceneReady {
            viewModel.setGameStateManager(coordinator.gameStateManager)
        }
    }
    
    private var mapTopBarControl: some View {
        HStack(alignment: .top) {
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
            
            Text(viewModel.mapStatistics)
                .laborFont(10)
            
            Spacer()
        }
        .padding()
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
