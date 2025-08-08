import UIKit

// MARK: - アプリの設定画面を開く
struct AppSettings {
    static func open() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
