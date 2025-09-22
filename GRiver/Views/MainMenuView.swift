import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var viewModel: MainMenuViewModel
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            logoSection
            
            if viewModel.hasSavedGame {
                savedGameInfoSection
            }
            
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
            viewModel.checkForSavedGame()
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
                    .frame(maxWidth: 300)
                    .overlay {
                        Text(viewModel.playButtonText)
                            .laborFont(24)
                    }
            }
            
             HStack {
                 Button {
                     // ShopView()
                 } label: {
                     Image(.rectangleButton)
                         .resizable()
                         .scaledToFit()
                         .frame(maxWidth: 200)
                         .overlay {
                             Text("Shop")
                                 .laborFont(20)
                         }
                 }
                
                 Button {
                     // AchieveView()
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
                     // DailyTasksView()
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
                     // SettingsView()
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
                Button {
                    viewModel.handleManageProgress()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage Progress")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: 200)
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                if viewModel.showManageProgress {
                    Button {
                        viewModel.handleDeleteProgress()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: 200)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.5))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var savedGameInfoSection: some View {
        VStack {
            VStack(alignment: .trailing, spacing: 4) {
                Text("Saved Game Available")
                    .laborFont(10)
                
                Text(viewModel.savedGameInfo)
                    .laborFont(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
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
}

#Preview {
    MainMenuView()
        .environmentObject(MainMenuViewModel())
        .preferredColorScheme(.dark)
}
