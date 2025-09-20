import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var viewModel: MainMenuViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            titleSection
            
            mainButtonsSection
            
            if viewModel.hasSavedGame {
                savedGameInfoSection
            }
            
            Spacer()
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
        .confirmationDialog("Delete Saved Game?", isPresented: $viewModel.showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.confirmDeleteSave()
            }
            Button("Cancel", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text("All progress will be lost permanently. This cannot be undone.")
        }
        .onAppear {
            viewModel.checkForSavedGame()
        }
    }
    
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
    
    private var mainButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.handlePlayAction()
            }) {
                HStack {
                    Image(systemName: playButtonIcon)
                    Text(viewModel.playButtonText)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            
            if viewModel.hasSavedGame {
                Button(action: {
                    viewModel.handleManageProgress()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage Progress")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                if viewModel.showManageProgress {
                    Button(action: {
                        viewModel.handleDeleteProgress()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Progress")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var playButtonIcon: String {
        return viewModel.hasSavedGame ? "arrow.clockwise.circle" : "plus.circle"
    }
    
    private var savedGameInfoSection: some View {
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
}

#Preview {
    MainMenuView()
        .environmentObject(MainMenuViewModel())
        .preferredColorScheme(.dark)
}
