import Foundation
import UserNotifications

// MARK: - 通知の許可を確認する
struct NotificationPermissionManager {
    static func checkPermission(_ handler: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    handler(granted)
                }
            case .denied:
                handler(false)
            default:
                handler(true)
            }
        }
    }
}