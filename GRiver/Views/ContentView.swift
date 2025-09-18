import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content with navigation
                NavigationStack(path: $coordinator.navigationPath) {
                    currentView
                        .navigationDestination(for: AppFlowState.self) { destination in
                            destinationView(for: destination)
                        }
                }
                
                // Action Overlay
                if coordinator.showActionOverlay,
                   let poi = coordinator.selectedPOI {
                    ActionOverlayView(
                        poi: poi,
                        position: coordinator.overlayPosition,
                        onCancel: {
                            coordinator.hideActionOverlay()
                        },
                        onActionExecuted: { result in
                            coordinator.handleOperationResult(result)
                        }
                    )
                    .zIndex(10)
                }
                
                // Operation Result Overlay
                if coordinator.showOperationResult,
                   let result = coordinator.currentOperationResult {
                    OperationResultStandaloneView(
                        operationResult: result,
                        onContinue: {
                            coordinator.hideOperationResult()
                        }
                    )
                    .zIndex(11)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            coordinator.handleAppDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            coordinator.handleAppWillEnterForeground()
        }
    }
    
    // MARK: - Current View
    @ViewBuilder
    private var currentView: some View {
        switch coordinator.currentFlow {
        case .mainMenu:
            MainMenuView()
                .environmentObject(coordinator.mainMenuViewModel)
                .onAppear {
                    coordinator.hideAllOverlays()
                }
            
        case .gameMap:
            GameMapIntegratedView()
                .environmentObject(coordinator)
            
        case .playerBase:
            PlayerBaseIntegratedView()
                .environmentObject(coordinator)
            
        case .operationResult:
            // This state is handled by overlay, fallback to game map
            GameMapIntegratedView()
                .environmentObject(coordinator)
            
        case .gameOver:
            GameOverView()
                .environmentObject(coordinator)
        }
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for destination: AppFlowState) -> some View {
        switch destination {
        case .mainMenu:
            MainMenuView()
                .environmentObject(coordinator.mainMenuViewModel)
            
        case .gameMap:
            GameMapIntegratedView()
                .environmentObject(coordinator)
            
        case .playerBase:
            PlayerBaseIntegratedView()
                .environmentObject(coordinator)
            
        case .operationResult:
            // Handled by overlay, show game map
            GameMapIntegratedView()
                .environmentObject(coordinator)
            
        case .gameOver:
            GameOverView()
                .environmentObject(coordinator)
        }
    }
}

// MARK: - Integrated Views
struct GameMapIntegratedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        GameMapView()
            .environmentObject(coordinator.getGameSceneViewModel())
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Menu") {
                        coordinator.navigateToMainMenu()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Base") {
                        coordinator.navigateToPlayerBase()
                    }
                    .foregroundColor(.white)
                }
            }
    }
}

struct PlayerBaseIntegratedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        PlayerBaseView()
            .environmentObject(coordinator.getBaseViewModel())
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        coordinator.navigateBack()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Map") {
                        coordinator.navigateToGameMap()
                    }
                }
            }
    }
}

// MARK: - Game Over View (Placeholder)
struct GameOverView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Game Over Header
            VStack(spacing: 8) {
                Text(gameOverTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(gameOverColor)
                
                Text(gameOverMessage)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Game Statistics
            if let gameState = coordinator.currentGameState {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Game Statistics")
                        .font(.headline)
                    
                    Text("Operations Performed: \(gameState.statistics.operationsPerformed)")
                    Text("Success Rate: \(Int(gameState.statistics.successRate * 100))%")
                    Text("POIs Captured: \(gameState.statistics.poisCaptured)")
                    Text("POIs Destroyed: \(gameState.statistics.poisDestroyed)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button("New Game") {
                    coordinator.startNewGame()
                    coordinator.navigateToGameMap()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Main Menu") {
                    coordinator.navigateToMainMenu()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
    
    private var gameOverTitle: String {
        guard let gameState = coordinator.currentGameState else { return "GAME OVER" }
        
        switch gameState.status {
        case .victory: return "VICTORY!"
        case .defeat: return "DEFEAT"
        default: return "GAME OVER"
        }
    }
    
    private var gameOverColor: Color {
        guard let gameState = coordinator.currentGameState else { return .red }
        
        switch gameState.status {
        case .victory: return .green
        case .defeat: return .red
        default: return .orange
        }
    }
    
    private var gameOverMessage: String {
        guard let gameState = coordinator.currentGameState else { return "Game ended" }
        
        switch gameState.status {
        case .victory: return "All objectives completed!\nYou have secured the region."
        case .defeat: return "Your base was discovered!\nThe mission has failed."
        default: return "Game session ended"
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
