import SwiftUI

struct ContentSourceView: View {
    
    @StateObject private var manager = AppStateManager()
        
    var body: some View {
        Group {
            switch manager.appState {
            case .request:
                LoadingView()
                
            case .support:
                if let url = manager.networkManager.gameURL {
                    WKWebViewManager(
                        url: url,
                        webManager: manager.networkManager
                    )
                } else {
                    WKWebViewManager(
                        url: NetworkManager.initialURL,
                        webManager: manager.networkManager
                    )
                }
                
            case .loading:
                ContentView()
                    .preferredColorScheme(.light)
            }
        }
        .onAppear {
            manager.stateRequest()
        }
    }
}

#Preview {
    ContentSourceView()
}
