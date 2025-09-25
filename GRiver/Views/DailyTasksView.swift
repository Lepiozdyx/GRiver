import SwiftUI

struct DailyTasksView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var achievementsManager = AchievementsManager.shared
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            topBarControl
            
            tasksContent
        }
        .navigationBarBackButtonHidden(true)
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
                        Text("Daily tasks")
                            .laborFont(20)
                    }
                
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
    
    private var tasksContent: some View {
        ZStack {
            Image(.frame1)
                .resizable()
                .frame(width: 650, height: 250)
            
            HStack(spacing: 10) {
                taskView("play for at least 60 minutes")
                taskView("destroy at least 100 soldiers in the game")
                taskView("accumulate 200 cartridges")
                taskView("destroy all of your opponent's buildings")
                taskView("capture all of your opponent's buildings")
            }
        }
    }
    
    private func taskView(_ text: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Image(.squareButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
                    .overlay {
                        Text(text)
                            .laborFont(8)
                            .offset(y: 20)
                            .frame(width: 80)
                    }
                
                VStack {
                    Image(.calendar)
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
                .opacity(0.5)
                .colorMultiply(.gray)
        }
    }
}

#Preview {
    DailyTasksView()
        .environmentObject(AppCoordinator())
}
