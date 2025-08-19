import SwiftUI
import Foundation
import UserNotifications

// MARK: - リマインダーの行を表示するためのビュー
struct ReminderRowView: View {
    @ObservedObject var reminder: Reminder
    @Binding var editingReminder: Reminder?
    @Binding var showAlert: Bool
    var onRegister: () -> Void
    var categories: [String]
    
    var isEditing: Bool {
        editingReminder?.id == reminder.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("タイトルを入力", text: $reminder.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)

                DatePicker("日時", selection: $reminder.date, in: Date()..., displayedComponents: [.date, .hourAndMinute])

                Picker("カテゴリー", selection: $reminder.category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())

            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(reminder.title.isEmpty ? "（タイトルなし）" : reminder.title)
                        .font(.headline)
                    
                    Text(formattedDate(reminder.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.6), lineWidth: 0.6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if editingReminder?.id == reminder.id {
                registerAndClose(reminder)
            } else {
                editingReminder = reminder
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }

    // MARK: - 日時をフォーマットする
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy / M / d (E) HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - リマインダーを登録する
    private func registerAndClose(_ reminder: Reminder) {
        if reminder.date <= Date() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = reminder.title.isEmpty ? "（タイトル未入力）" : reminder.title  
        content.body = reminder.date.formatted(.dateTime.hour().minute())
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        UNUserNotificationCenter.current().add(request)

        onRegister()
        editingReminder = nil
    }
}