import SwiftUI

class OrientationManager {
    static let shared = OrientationManager()
    
    private init() {}
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        OrientationHelper.orientationMask = orientation
        if orientation != .all {
            OrientationHelper.isAutoRotationEnabled = false
        } else {
            OrientationHelper.isAutoRotationEnabled = true
        }
        requestOrientationUpdate()
    }
    
    func lockLandscape() {
        OrientationHelper.orientationMask = .landscape
        OrientationHelper.isAutoRotationEnabled = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if windowScene.interfaceOrientation.isPortrait {
                OrientationHelper.isAutoRotationEnabled = true
                requestOrientationUpdate()
                
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                
                OrientationHelper.isAutoRotationEnabled = false
            }
        }
    }
    
    func unlockOrientation() {
        OrientationHelper.orientationMask = .all
        OrientationHelper.isAutoRotationEnabled = true
        requestOrientationUpdate()
    }
    
    // MARK: - Private Methods
    
    private func requestOrientationUpdate() {
        if let viewController = getCurrentViewController() {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    private func getCurrentViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        return findTopViewController(from: window.rootViewController)
    }
    
    private func findTopViewController(from viewController: UIViewController?) -> UIViewController? {
        if let presentedViewController = viewController?.presentedViewController {
            return findTopViewController(from: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController)
        }
        
        return viewController
    }
}

class CustomHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationHelper.orientationMask
    }

    override var shouldAutorotate: Bool {
        return OrientationHelper.isAutoRotationEnabled
    }
}

class OrientationHelper {
    public static var orientationMask: UIInterfaceOrientationMask = .landscapeLeft
    public static var isAutoRotationEnabled: Bool = false
}
