import SwiftUI
import SpriteKit

struct GameMapView: View {
    @EnvironmentObject var viewModel: GameSceneViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            if viewModel.isSceneReady, let scene = viewModel.scene {
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
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
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading Tactical Map...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("Initializing POI data...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if viewModel.isSceneReady {
                VStack {
                    HStack(alignment: .top) {
                        mapStatsOverlay
                        
                        Spacer()
                        
                        mapControlButtons
                    }
                    .padding()
                    
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
            ensureSceneInitialization()
        }
    }
    
    private func ensureSceneInitialization() {
        if !viewModel.isSceneReady && coordinator.isGameActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !viewModel.isSceneReady {
                    viewModel.setGameStateManager(coordinator.gameStateManager)
                }
            }
        }
    }
    
    private var mapStatsOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MAP STATUS")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.mapStatistics)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    private var mapControlButtons: some View {
        VStack(spacing: 8) {
            Button("Menu") {
                coordinator.navigateToMainMenu()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.white)
            
            Button("Base") {
                coordinator.showBaseManagement()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .foregroundColor(.white)
        }
    }
    
    private var bottomOverlay: some View {
        Group {
            if let selectedPOI = viewModel.selectedPOI {
                selectedPOIInfo(selectedPOI)
                    .padding(.bottom, 20)
            } else {
                mapInstructions
                    .padding(.bottom, 20)
            }
        }
    }
    
    private func selectedPOIInfo(_ poi: PointOfInterest) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(poi.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Status: \(poi.status.displayName)")
                    .font(.caption)
                    .foregroundColor(poi.isOperational ? .green : .red)
                
                Text("Defense: \(poi.totalDefense) | Units: \(poi.currentUnits)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if poi.defenseBonus > 0 {
                    Text("Alert Bonus: +\(poi.defenseBonus)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            HStack(spacing: 12) {
                Button("Focus") {
                    viewModel.focusOnPOI(poi)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if poi.isOperational {
                    Button("Select") {
                        selectPOIForAction(poi)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.green)
                }
                
                Button("Close") {
                    viewModel.deselectPOI()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private var mapInstructions: some View {
        VStack(spacing: 4) {
            Text("TACTICAL MAP")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Tap POI to view details")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text("Pinch to zoom • Drag to pan")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    private var baseManagementOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    coordinator.hideBaseManagement()
                }
            
            PlayerBaseView(
                isOverlay: true,
                onClose: {
                    coordinator.hideBaseManagement()
                }
            )
            .environmentObject(coordinator.getBaseViewModel())
            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500))
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .background(Color(.systemBackground))
            .cornerRadius(12)
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
