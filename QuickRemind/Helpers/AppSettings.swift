import UIKit

// MARK: - アプリの設定画面を開く
struct AppSettings {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
