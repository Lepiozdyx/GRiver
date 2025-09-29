import Foundation
import Combine

@MainActor
final class AppStateManager: ObservableObject {
    enum AppState {
        case fetch
        case supp
        case final
    }
    
    @Published private(set) var appState: AppState = .fetch
    let webManager: NetworkManager
    
    private var timeoutTask: Task<Void, Never>?
    private let maxLoadingTime: TimeInterval = 15.0
    
    init(webManager: NetworkManager) {
        self.webManager = webManager
    }
    
    convenience init() {
        self.init(webManager: NetworkManager())
    }
    
    func stateCheck() {
        timeoutTask?.cancel()
        
        Task { @MainActor in
            do {
                if webManager.targetURL != nil {
                    updateState(.supp)
                    return
                }
                
                let shouldShowWebView = try await webManager.checkInitialURL()
                
                if shouldShowWebView {
                    updateState(.supp)
                } else {
                    updateState(.final)
                }
                
            } catch {
                print("StateCheck error: \(error.localizedDescription)")
                updateState(.final)
            }
        }
        
        startTimeoutTask()
    }
    
    private func updateState(_ newState: AppState) {
        timeoutTask?.cancel()
        timeoutTask = nil
        
        appState = newState
    }
    
    private func startTimeoutTask() {
        timeoutTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: UInt64(maxLoadingTime * 1_000_000_000))
                
                if self.appState == .fetch {
                    self.appState = .final
                }
            } catch {
                print("AppStateManager: Task was cancelled (timeout)")
            }
        }
    }
    
    deinit {
        timeoutTask?.cancel()
    }
}

