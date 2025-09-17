import SwiftUI
import SpriteKit

// MARK: - Game Map View
struct GameMapView: View {
    @StateObject private var viewModel = GameSceneViewModel()
    
    var body: some View {
        ZStack {
            // SpriteKit Scene
            SpriteView(scene: viewModel.createScene())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            
            // Debug overlay (top)
            VStack {
                HStack(alignment: .top) {
                    // Map statistics
                    Text(viewModel.mapStatistics)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Control buttons
                    VStack(spacing: 8) {
                        Button("Reset Camera") {
                            viewModel.resetCamera()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Reset Map") {
                            viewModel.resetMapToDefault()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding()
                
                Spacer()
                
                // Selected POI info (bottom)
                if let selectedPOI = viewModel.selectedPOI {
                    selectedPOIOverlay(selectedPOI)
                        .padding(.bottom, 20)
                } else {
                    // Instructions
                    Text("Tap on a POI to select it\nPinch to zoom, drag to pan")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    // MARK: - Selected POI Overlay
    @ViewBuilder
    private func selectedPOIOverlay(_ poi: PointOfInterest) -> some View {
        VStack(spacing: 12) {
            // POI Info
            VStack(spacing: 4) {
                Text(poi.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Status: \(poi.status.displayName)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Defense: \(poi.totalDefense) | Units: \(poi.currentUnits)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Test Actions
            HStack(spacing: 12) {
                Button("Focus") {
                    viewModel.focusOnPOI(poi)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if poi.isOperational {
                    Button("Test Capture") {
                        viewModel.testCapturePOI(poi)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Test Destroy") {
                        viewModel.testDestroyPOI(poi)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button("Deselect") {
                    viewModel.deselectPOI()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - Preview
#Preview {
    GameMapView()
        .preferredColorScheme(.dark)
}
