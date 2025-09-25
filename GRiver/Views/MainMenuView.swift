import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var viewModel: MainMenuViewModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            soldierSection
            
            logoSection
            
            mangeButtonSection
            
            mainButtonsSection
        }
        .navigationBarHidden(true)
        .alert(viewModel.alertTitle, isPresented: $viewModel.showLoadError) {
            Button("OK") {
                viewModel.dismissAlert()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .confirmationDialog("Delete Saved Game?", isPresented: $viewModel.showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.confirmDeleteSave()
            }
            Button("Cancel", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text("All progress will be lost permanently. Sure?")
        }
        .onAppear {
//            OrientationManager.shared.lockLandscape()
            settings.playBackgroundMusic()
            viewModel.checkForSavedGame()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
//                OrientationManager.shared.lockLandscape()
                settings.playBackgroundMusic()
            case .background, .inactive:
                settings.stopBackgroundMusic()
            @unknown default:
                break
            }
        }
    }
    
    private var mainButtonsSection: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Button {
                viewModel.handlePlayAction()
            } label: {
                Image(.rectangleButton)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250)
                    .overlay {
                        Text(viewModel.playButtonText)
                            .laborFont(24)
                    }
            }
            
             HStack { 
                 Button {
                     viewModel.handleAchievementsAction()
                 } label: {
                     Image(.rectangleButton)
                         .resizable()
                         .scaledToFit()
                         .frame(maxWidth: 200)
                         .overlay {
                             Text("Achieve")
                                 .laborFont(20)
                         }
                 }
                 
                 Button {
                     viewModel.handleDailyTasksAction()
                 } label: {
                     Image(.rectangleButton)
                         .resizable()
                         .scaledToFit()
                         .frame(maxWidth: 200)
                         .overlay {
                             Text("Daily Tasks")
                                 .laborFont(20)
                         }
                 }
                 
                 Button {
                     viewModel.handleSettingsAction()
                 } label: {
                     Image(.rectangleButton)
                         .resizable()
                         .scaledToFit()
                         .frame(maxWidth: 200)
                         .overlay {
                             Text("Settings")
                                 .laborFont(20)
                         }
                 }
             }
        }
        .padding()
    }
    
    private var mangeButtonSection: some View {
        VStack {
            if viewModel.hasSavedGame {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Game Available")
                        .laborFont(10)
                    
                    Text(viewModel.savedGameInfo)
                        .laborFont(8)
                }
            }
            
            if viewModel.hasSavedGame {
                Button {
                    viewModel.handleManageProgress()
                } label: {
                    Image(.rectangleButton)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 150)
                        .overlay {
                            HStack(spacing: 2) {
                                Image(systemName: "gear")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16))
                                
                                Text("Manage Progress")
                                    .laborFont(8)
                            }
                        }
                }
                
                if viewModel.showManageProgress {
                    Button {
                        viewModel.handleDeleteProgress()
                    } label: {
                        Image(.rectangleButton)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 150)
                            .overlay {
                                HStack(spacing: 2) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 16))
                                    
                                    Text("Delete")
                                        .laborFont(8, color: .red)
                                }
                            }
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var logoSection: some View {
        VStack {
            Image(.logo)
                .resizable()
                .frame(width: 100, height: 100)
            
            Spacer()
        }
        .padding()
    }
    
    private var soldierSection: some View {
        HStack {
            Spacer()
            
            VStack {
                Spacer()
                
                Image(.character1)
                    .resizable()
                    .frame(width: 250, height: 350)
                    .offset(y: 30)
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(MainMenuViewModel())
}
