import SwiftUI

// MARK: - Main Menu View
struct MainMenuView: View {
    @EnvironmentObject var viewModel: MainMenuViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            // MARK: - Title Section
            titleSection
            
            // MARK: - Game Status Section
            if viewModel.isGameActive {
                gameStatusSection
            }
            
            // MARK: - Main Buttons Section
            mainButtonsSection
            
            // MARK: - Secondary Actions Section
            secondaryActionsSection
            
            Spacer()
            
            // MARK: - Debug Info Section
            if viewModel.isGameActive {
                debugInfoSection
            }
        }
        .padding()
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert(viewModel.alertTitle, isPresented: $viewModel.showLoadError) {
            Button("OK") {
                viewModel.dismissAlert()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .confirmationDialog("Start New Game?", isPresented: $viewModel.showNewGameConfirm) {
            Button("New Game", role: .destructive) {
                viewModel.confirmNewGame()
            }
            Button("Cancel", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text("This will overwrite your current progress.")
        }
        .confirmationDialog("Exit Game?", isPresented: $viewModel.showExitConfirm) {
            Button("Exit", role: .destructive) {
                viewModel.confirmExit()
            }
            Button("Cancel", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text("Your progress will be saved automatically.")
        }
        .onAppear {
            viewModel.checkForSavedGame()
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("GLOBAL STRATEGY")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Tactical Operations")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Game Status Section
    private var gameStatusSection: some View {
        VStack(spacing: 8) {
            Text("Current Game")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(viewModel.gameProgressSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("Status:")
                    .foregroundColor(.secondary)
                
                Text(viewModel.gameStatus.displayName)
                    .foregroundColor(gameStatusColor)
                    .fontWeight(.medium)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var gameStatusColor: Color {
        switch viewModel.gameStatus {
        case .playing: return .green
        case .paused: return .orange
        case .victory: return .blue
        case .defeat: return .red
        }
    }
    
    // MARK: - Main Buttons Section
    private var mainButtonsSection: some View {
        VStack(spacing: 16) {
            
            // Play Button - navigation handled externally
            Button(action: {
                // Let the parent coordinator handle the navigation flow
                viewModel.handlePlayAction()
            }) {
                HStack {
                    Image(systemName: playButtonIcon)
                    Text(viewModel.playButtonText)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Base Button - navigation handled externally
            Button(action: {
                // Let the parent coordinator handle the navigation flow
                viewModel.handleBaseAction()
            }) {
                HStack {
                    Image(systemName: "building.2")
                    Text("Manage Base")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    private var playButtonIcon: String {
        switch viewModel.gameStatus {
        case .paused: return "play.circle"
        case .playing: return "map"
        default: return "plus.circle"
        }
    }
    
    // MARK: - Secondary Actions Section
    private var secondaryActionsSection: some View {
        VStack(spacing: 12) {
            
            // Save Game Info
            if viewModel.hasSavedGame {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Game Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.savedGameInfo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(4)
            }
            
            HStack(spacing: 12) {
                
                // Delete Save Button (if has save)
                if viewModel.hasSavedGame {
                    Button("Delete Save") {
                        viewModel.deleteSavedGame()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                // Settings/Debug Button
                Button("Debug Info") {
                    viewModel.simulateGameProgress()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                // Exit Button
                Button("Exit") {
                    viewModel.handleExitAction()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Debug Info Section
    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug Information")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(viewModel.debugInfo)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
    }
}

// MARK: - Preview
#Preview {
    MainMenuView()
        .environmentObject(MainMenuViewModel())
        .preferredColorScheme(.dark)
}
