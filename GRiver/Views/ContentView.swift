import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationStack(path: $coordinator.navigationPath) {
                    currentView
                        .navigationDestination(for: AppFlowState.self) { destination in
                            destinationView(for: destination)
                        }
                }
                
                // Action Overlay - изменен колбэк
                if coordinator.showActionOverlay,
                   let poi = coordinator.selectedPOI {
                    ActionOverlayView(
                        viewModel: coordinator.getActionOverlayViewModel(),
                        poi: poi,
                        onCancel: {
                            coordinator.hideActionOverlay()
                        },
                        onActionRequested: { actionType, poi in
                            coordinator.executeOperation(actionType: actionType, targetPOI: poi)
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
        .onReceive(NotificationCenter.default.publisher(for: .requestActionOverlay)) { notification in
            handleActionOverlayRequest(notification)
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
            GameMapView()
                .environmentObject(coordinator.getGameSceneViewModel())
                .environmentObject(coordinator)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Menu") {
                            coordinator.navigateToMainMenu()
                        }
                        .foregroundColor(.white)
                    }
                }
            
        case .operationResult:
            GameMapView()
                .environmentObject(coordinator.getGameSceneViewModel())
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
            GameMapView()
                .environmentObject(coordinator.getGameSceneViewModel())
                .environmentObject(coordinator)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Menu") {
                            coordinator.navigateToMainMenu()
                        }
                        .foregroundColor(.white)
                    }
                }
            
        case .operationResult:
            GameMapView()
                .environmentObject(coordinator.getGameSceneViewModel())
                .environmentObject(coordinator)
            
        case .gameOver:
            GameOverView()
                .environmentObject(coordinator)
        }
    }
    
    // MARK: - Action Overlay Request Handler
    private func handleActionOverlayRequest(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let poi = userInfo["poi"] as? PointOfInterest,
              let position = userInfo["position"] as? CGPoint else { return }
        
        coordinator.handlePOISelected(poi, at: position)
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            
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
            
            if let gameState = coordinator.currentGameState {
                gameStatisticsSection(gameState)
            }
            
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
                
                Button("Reset All") {
                    coordinator.resetToMainMenu()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
    
    private func gameStatisticsSection(_ gameState: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mission Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                statCard("Operations", "\(gameState.statistics.operationsPerformed)")
                statCard("Success Rate", "\(Int(gameState.statistics.successRate * 100))%")
                statCard("POIs Captured", "\(gameState.statistics.poisCaptured)")
                statCard("POIs Destroyed", "\(gameState.statistics.poisDestroyed)")
            }
            
            let progress = Int(gameState.completionPercentage * 100)
            Text("Mission Progress: \(progress)%")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statCard(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
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
