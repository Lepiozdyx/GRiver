import SwiftUI
import SpriteKit

// MARK: - Game Map View
struct GameMapView: View {
    @EnvironmentObject var viewModel: GameSceneViewModel
    
    var body: some View {
        ZStack {
            // SpriteKit Scene
            SpriteView(scene: viewModel.createScene())
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
            
            // HUD Overlay
            VStack {
                // Top HUD
                HStack(alignment: .top) {
                    // Map statistics
                    mapStatsOverlay
                    
                    Spacer()
                    
                    // Control buttons
                    mapControlButtons
                }
                .padding()
                
                Spacer()
                
                // Bottom instructions or selected POI info
                bottomOverlay
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            viewModel.refreshMap()
        }
    }
    
    // MARK: - Map Stats Overlay
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
    
    // MARK: - Map Control Buttons
    private var mapControlButtons: some View {
        VStack(spacing: 8) {
            Button("Reset View") {
                viewModel.resetCamera()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .foregroundColor(.white)
            
            Button("Refresh") {
                viewModel.refreshMap()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Bottom Overlay
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
    
    // MARK: - Selected POI Info
    private func selectedPOIInfo(_ poi: PointOfInterest) -> some View {
        VStack(spacing: 8) {
            // POI Details
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
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Focus") {
                    viewModel.focusOnPOI(poi)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if poi.isOperational {
                    Button("Select") {
                        // This will trigger the action overlay
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
    
    // MARK: - Map Instructions
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
    
    // MARK: - POI Interaction Handlers
    private func handlePOISelected(_ poi: PointOfInterest, at position: CGPoint) {
        viewModel.selectPOI(poi, at: position)
    }
    
    private func handlePOIDeselected() {
        viewModel.deselectPOI()
    }
    
    private func selectPOIForAction(_ poi: PointOfInterest) {
        // Convert POI position to screen coordinates for overlay
        let screenPosition = CGPoint(x: 400, y: 300) // Center of screen for now
        
        // Send notification to parent coordinator to show action overlay
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

// MARK: - Notification Extensions
extension Notification.Name {
    static let requestActionOverlay = Notification.Name("requestActionOverlay")
}

// MARK: - Preview
#Preview {
    GameMapView()
        .environmentObject(GameSceneViewModel())
        .preferredColorScheme(.dark)
}
