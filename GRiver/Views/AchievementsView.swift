import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var achievementsManager = AchievementsManager.shared
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            topBarControl
            
            achievementsContent
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            checkAchievements()
        }
    }
    
    private var topBarControl: some View {
        VStack {
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
                
                Image(.frame1)
                    .resizable()
                    .frame(width: 200, height: 40)
                    .overlay {
                        Text("Achievements")
                            .laborFont(20)
                    }
                
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
    
    private var achievementsContent: some View {
        ZStack {
            Image(.frame1)
                .resizable()
                .frame(width: 650, height: 250)
            
            HStack(spacing: 10) {
                achievementView(.money1000, "1000 Coins")
                achievementView(.defeatByAlert, "Alert Defeat")
                achievementView(.units100, "100 Units")
                achievementView(.ammo1000, "1000 Ammo")
                achievementView(.victory, "Victory")
            }
        }
    }
    
    private func achievementView(_ achievement: Achievement, _ title: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Image(.squareButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
                    .overlay {
                        Text(achievementDescription(achievement))
                            .laborFont(8)
                            .offset(y: 20)
                            .frame(width: 100)
                    }
                
                VStack {
                    achievementIcon(achievement)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                    
                    Spacer()
                }
                .frame(height: 120)
            }
            
            Image(.rectangleButton)
                .resizable()
                .frame(width: 90, height: 30)
                .overlay {
                    HStack(spacing: 2) {
                        Image(.coin).resizable().frame(width: 15, height: 15)
                        Text("100")
                            .laborFont(12)
                        Image(.coin).resizable().frame(width: 15, height: 15)
                    }
                }
                .opacity(achievementsManager.isUnlocked(achievement) ? 1.0 : 0.5)
                .colorMultiply(achievementsManager.isUnlocked(achievement) ? .white : .gray)
        }
    }
    
    private func achievementIcon(_ achievement: Achievement) -> Image {
        switch achievement {
        case .money1000: return Image(.achieve1)
        case .defeatByAlert: return Image(.achieve2)
        case .units100: return Image(.achieve3)
        case .ammo1000: return Image(.achieve4)
        case .victory: return Image(.achieve5)
        }
    }
    
    private func achievementDescription(_ achievement: Achievement) -> String {
        switch achievement {
        case .money1000: return "Accumulate 1000 coins"
        case .defeatByAlert: return "Lose due to high alert"
        case .units100: return "Recruit 100 units"
        case .ammo1000: return "Buy 1000$ of ammo"
        case .victory: return "Win the game"
        }
    }
    
    private func checkAchievements() {
        guard let gameState = coordinator.currentGameState else { return }
        
        // Check money achievement
        if gameState.resources.money >= 1000 {
            achievementsManager.unlock(.money1000)
        }
        
        // Check defeat by alert achievement
        if gameState.status == .defeat && gameState.alertLevel >= 1.0 {
            achievementsManager.unlock(.defeatByAlert)
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AppCoordinator())
}
