import SwiftUI

extension ReminderView {
    
    // MARK: - 通知の許可を表示する
    func notificationPermissionAlert() -> Alert {
        Alert(
            title: Text("通知がオフになっています"),
            message: Text("通知をオンにすると、リマインダーが正常に動作します。\n設定から変更できます。"),
            primaryButton: .default(Text("設定を開く"), action: AppSettings.open),
            secondaryButton: .cancel(Text("今はしない"))
        )
    }
}
