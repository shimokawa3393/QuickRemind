import SwiftUI
import EventKit

extension ReminderView {
    // MARK: - Appleリマインダーと連携する
    @MainActor
    func linkReminders() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .notDetermined:
            let store = EKEventStore()
            store.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.reminderAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
                    self.isReminderAuthorized = granted
                    if granted {
                        reminderMessage = "リマインダーの利用が許可されました。"
                        showReminderOpenSettings = false
                        showReminderAlert = true
                    } else {
                        reminderMessage = "リマインダーの権限が拒否されています。\n設定アプリから変更してください。"
                        showReminderOpenSettings = true
                    }
                }
            }
            
        case .authorized:
            let result = ReminderService.loadReminderLists(selectedReminderListID: selectedReminderListID)
            availableReminderLists = result.reminderLists
            selectedReminderListID = result.selectedReminderListID
            showReminderOpenSettings = false
            showReminderPicker = true
            
        case .denied, .restricted:
            reminderMessage = "リマインダーの権限がオフです。\n設定アプリから変更してください。"
            showReminderOpenSettings = true
            showReminderAlert = true
            
        @unknown default:
            reminderMessage = "フルアクセスを許可でリマインダー連携を有効にしてください。"
            showReminderOpenSettings = true
            showReminderAlert = true
        }
    }
}
