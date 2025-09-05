import UIKit
import SwiftUI

enum AppReview {
    
    // MARK: - アプリを評価する
    @MainActor
    static func rateApp() {
        let appID = "6751082907" // QuickRemind の App Store ID
        // 1) まずは「レビューを書く」直行（最短）
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        // 2) 万一失敗時はアプリページへ（ユーザーが自分で★へ移動できる）
        if let fallback = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") {
            UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
        }
    }
}
