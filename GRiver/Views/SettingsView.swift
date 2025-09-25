import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            topBarControl
            
            ZStack {
                Image(.frame1)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 230)
                
                HStack(spacing: 60) {
                    VStack(spacing: 0) {
                        Image(.frame1)
                            .resizable()
                            .frame(width: 100, height: 25)
                            .overlay {
                                Text("Sounds")
                                    .laborFont(14)
                            }
                        
                        // Sounds
                        ToggleButtonView(isEnabled: settings.isSoundEnabled, icon: .radio) {
                            settings.toggleSound()
                        }
                    }
                    
                    VStack(spacing: 0) {
                        Image(.frame1)
                            .resizable()
                            .frame(width: 100, height: 25)
                            .overlay {
                                Text("Music")
                                    .laborFont(14)
                            }
                        
                        // Music
                        ToggleButtonView(isEnabled: settings.isMusicEnabled, icon: .sound) {
                            settings.toggleMusic()
                        }
                    }
                }
            }
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
                        Text("Settings")
                            .laborFont(20)
                    }
                
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
}

// MARK: - ToggleButtonView
struct ToggleButtonView: View {
    var isEnabled: Bool
    let icon: ImageResource
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .colorMultiply(isEnabled ? .white  : .gray)
                
                Spacer()
                
                Text(isEnabled ? "On" : "Off")
                    .laborFont(20)
            }
            .frame(height: 130)
        }
    }
}
