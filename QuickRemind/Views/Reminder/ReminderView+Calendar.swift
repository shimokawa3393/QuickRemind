import SwiftUI
import EventKit

extension ReminderView {
    // MARK: - Appleカレンダーと連携する
    @MainActor
    func linkCalendars() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            let store = EKEventStore()
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
                    self.isCalendarAuthorized = granted
                    if granted {
                        calendarMessage = "カレンダーの利用が許可されました。"
                        showCalendarOpenSettings = false
                        showCalendarAlert = true
                    } else {
                        calendarMessage = "カレンダーの権限が拒否されています。\n設定アプリからフルアクセスを許可してください。"
                        showCalendarOpenSettings = true
                    }
                }
            }
            
        case .authorized:
            let result = CalendarService.loadEventCalendars(selectedCalendarID: selectedCalendarID)
            availableCalendars = result.calendars
            selectedCalendarID = result.selectedCalendarID
            showCalendarOpenSettings = false
            showCalendarPicker = true
            
        case .denied, .restricted:
            calendarMessage = "カレンダーの権限がオフです。\n設定アプリからフルアクセスを許可してください。"
            showCalendarOpenSettings = true
            showCalendarAlert = true
            
        @unknown default:
            calendarMessage = "フルアクセスを許可でカレンダー連携を有効にしてください。"
            showCalendarOpenSettings = true
            showCalendarAlert = true
        }
    }
}
