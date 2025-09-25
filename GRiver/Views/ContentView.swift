import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        ZStack {
            NavigationStack(path: $coordinator.navigationPath) {
                currentView
                    .navigationDestination(for: AppFlowState.self) { destination in
                        destinationView(for: destination)
                    }
            }
            
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
                
        case .settings:
            SettingsView()
                .environmentObject(coordinator)
                
        case .shop:
            ShopView()
                .environmentObject(coordinator)
                
        case .achievements:
            AchievementsView()
                .environmentObject(coordinator)
                
        case .dailyTasks:
            DailyTasksView()
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
                
        case .settings:
            SettingsView()
                .environmentObject(coordinator)
                
        case .shop:
            ShopView()
                .environmentObject(coordinator)
                
        case .achievements:
            AchievementsView()
                .environmentObject(coordinator)
                
        case .dailyTasks:
            DailyTasksView()
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
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            VStack {
                Spacer()
                
                gameOverContent
                
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var gameOverContent: some View {
        VStack(spacing: 16) {
            gameOverHeader
            
            if let gameState = coordinator.currentGameState {
                gameStatisticsSection(gameState)
            }
            
            Button {
                coordinator.navigateToMainMenu()
            } label: {
                Image(.rectangleButton)
                    .resizable()
                    .frame(width: 150, height: 50)
                    .overlay {
                        Text("Main Menu")
                            .laborFont(16)
                    }
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
        .background(
            Image(.frame1)
                .resizable()
        )
        .frame(maxWidth: 400)
    }
    
    private var gameOverHeader: some View {
        VStack(spacing: 8) {
            Text(gameOverTitle)
                .laborFont(18, color: gameOverColor)
            
            Text(gameOverMessage)
                .laborFont(14, color: .white.opacity(0.8))
        }
    }
    
    private func gameStatisticsSection(_ gameState: GameState) -> some View {
        VStack(spacing: 4) {
            statisticsRow("Operations", "\(gameState.statistics.operationsPerformed)")
            statisticsRow("Success Rate", "\(Int(gameState.statistics.successRate * 100))%")
            statisticsRow("POIs Captured", "\(gameState.statistics.poisCaptured)")
            statisticsRow("POIs Destroyed", "\(gameState.statistics.poisDestroyed)")
            
            let progress = Int(gameState.completionPercentage * 100)
            statisticsRow("Progress", "\(progress)%")
        }
    }
    
    private func statisticsRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .laborFont(12)
            
            Spacer()
            
            Text(value)
                .laborFont(12, color: .green)
        }
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

// MARK: - New View Stubs
struct ShopView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            VStack {
                topBar
                
                Spacer()
                
                Text("Shop Coming Soon")
                    .laborFont(24)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var topBar: some View {
        HStack {
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
            
            Text("Shop")
                .laborFont(20)
            
            Spacer()
        }
        .padding()
    }
}

struct AchievementsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            VStack {
                topBar
                
                Spacer()
                
                Text("Achievements Coming Soon")
                    .laborFont(24)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var topBar: some View {
        HStack {
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
            
            Text("Achievements")
                .laborFont(20)
            
            Spacer()
        }
        .padding()
    }
}

struct DailyTasksView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            VStack {
                topBar
                
                Spacer()
                
                Text("Daily Tasks Coming Soon")
                    .laborFont(24)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var topBar: some View {
        HStack {
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
            
            Text("Daily Tasks")
                .laborFont(20)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
