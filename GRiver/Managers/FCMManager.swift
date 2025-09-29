import FirebaseMessaging
import Combine

class FCMManager: ObservableObject {
    static let shared = FCMManager()
    
    @Published private(set) var fcmToken: String?
    private var continuation: CheckedContinuation<String, Never>?
    
    private init() {}
    
    func setToken(_ token: String) {
        self.fcmToken = token
        continuation?.resume(returning: token)
        continuation = nil
    }
    
    func waitForToken() async -> String {
        if let existingToken = fcmToken {
            return existingToken
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}
