import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        OrientationHelper.orientationMask = .all
        OrientationHelper.isAutoRotationEnabled = true
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        requestNotificationPermission()
        
        application.registerForRemoteNotifications()
        
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handlePushNotification(userInfo)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationHelper.orientationMask
    }
    
    private func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
                return
            }
            
            print(granted ? "Notifications enabled" : "Notifications disabled")
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let _ = tokenParts.joined()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handlePushNotification(userInfo)
        completionHandler(.newData)
    }
    
    private func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("FCM token is nil")
            return
        }
        
        let previousToken = FCMManager.shared.fcmToken
        let isTokenChanged = previousToken != token
        
        if isTokenChanged {
            if let prev = previousToken {
                print("Token CHANGED!")
                print("Previous: \(prev)")
                print("New: \(token)")
            } else {
                print("First time receiving token")
            }
        } else {
            print("Same token as before")
        }
        
        FCMManager.shared.setToken(token)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        handlePushNotification(userInfo)
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let _ = response.actionIdentifier
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            print("Default action - notification tapped")
        case UNNotificationDismissActionIdentifier:
            print("Notification dismissed")
        default:
            print("Custom action: \(response.actionIdentifier)")
        }
        
        handlePushNotification(userInfo)
        completionHandler()
    }
}
