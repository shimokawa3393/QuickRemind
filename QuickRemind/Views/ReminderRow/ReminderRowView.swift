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
    var focused: FocusState<UUID?>.Binding
    
    var isEditing: Bool {
        editingReminder?.id == reminder.id
    }

    // MARK: - 最小選択可能日時を設定する
    private var minSelectableDate: Date {
        Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("タイトルを入力", text: $reminder.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle()) // テキストフィールドのスタイル
                    .disableAutocorrection(true)                   // 自動修正を無効化
                    .textInputAutocapitalization(.never)           // テキストフィールドのキャピタライゼーションを無効化
                    .focused(focused, equals: reminder.id)                        // フォーカスを設定
                
                DatePicker("日時",
                           selection: $reminder.date,
                           in: minSelectableDate...,
                           displayedComponents: [.date, .hourAndMinute])
                
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
                    
                    Text(DateFormat.formattedDate(reminder.date))
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
                // ここで最低1分先に寄せる（現在や過去を選んでいても救済）
                if reminder.date <= Date() {
                    reminder.date = minSelectableDate
                }
                editingReminder = reminder
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}
