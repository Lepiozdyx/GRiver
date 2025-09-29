import SwiftUI

@main
struct GRiverApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentSourceView()
        }
    }
}
