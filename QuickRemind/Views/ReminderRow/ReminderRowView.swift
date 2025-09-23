import SwiftUI
import Foundation
import UserNotifications
import EventKit

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


    // MARK: - 分丸め設定
    @AppStorage(kMinuteGranularityKey) private var minuteGranularityRaw = MinuteGranularity.min15.rawValue
    @AppStorage(kRoundingModeKey)      private var roundingModeRaw = "nearest"
    @AppStorage(kDefaultSaveDestinationKey) private var defaultSaveDestinationRaw = SaveDestination.appOnly.rawValue

    private var minuteGranularity: MinuteGranularity {
        MinuteGranularity(rawValue: minuteGranularityRaw) ?? .min15
    }
    private var roundingMode: RoundingMode {
        switch roundingModeRaw { case "up": .up; case "down": .down; default: .nearest }
    }
    private var defaultSaveDestination: SaveDestination {
        SaveDestination(rawValue: defaultSaveDestinationRaw) ?? .appOnly
    }

    func roundedDate(date: Date) -> Date {
        date.rounded(toMinuteInterval: minuteGranularity.minuteInterval, mode: roundingMode)
    }

    
    // MARK: - 権限状態
    var reminderAccess: EKAccess { EKAccess.accessLevel(for: .reminder) }
    var calendarAccess: EKAccess { EKAccess.accessLevel(for: .event) }
    
    // ピッカー表示可否（どちらかが権限ありなら表示）
    var canShowDestinationPicker: Bool {
        reminderAccess == .full || calendarAccess == .full
    }
    
    // 選択肢の可否
    var canUseReminders: Bool { reminderAccess == .full }
    var canUseCalendar:  Bool { calendarAccess  == .full }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("タイトルを入力", text: $reminder.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle()) // テキストフィールドのスタイル
                    .disableAutocorrection(true)                   // 自動修正を無効化
                    .textInputAutocapitalization(.never)           // テキストフィールドのキャピタライゼーションを無効化
                    .focused(focused, equals: reminder.id)                        // フォーカスを設定
                                
                // UI は5分刻みのホイール、かつ 値は常に丸める
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("日時")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        // 値は常に丸めて反映（最近接/上/下のモードも適用）
                        MinuteIntervalDatePicker(
                            date: Binding(
                                get: { reminder.date },
                                set: { newValue in
                                    reminder.date = roundedDate(date: newValue)
                                }
                            ),
                            minuteInterval: minuteGranularity.minuteInterval
                        )
                    }
                }
                Picker("カテゴリー", selection: $reminder.category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                if canShowDestinationPicker {
                    Picker("保存先", selection: $reminder.saveDestination) {
                        Text("アプリ内のみ").tag(SaveDestination.appOnly)
                        if canUseCalendar  { Text("＋Appleカレンダー").tag(SaveDestination.calendar) }
                        if canUseReminders { Text("＋Appleリマインダー").tag(SaveDestination.reminders) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    // 利用不可の選択肢に入っていた場合は強制補正
                    .onAppear { 
                        // 新規リマインダー作成時のみデフォルト保存先を設定
                        if reminder.saveDestination == .appOnly && defaultSaveDestination != .appOnly {
                            reminder.saveDestination = defaultSaveDestination
                        }
                        normalizeDestination() 
                    }
                    .onChange(of: reminder.title) { _ in normalizeDestination() } // 編集中に権限変更された場合の保険
                    .onChange(of: reminder.date)  { _ in normalizeDestination() }
                    .onChange(of: reminder.saveDestination) { newValue in
                        // 保存先が変更されたらデフォルト値を更新
                        defaultSaveDestinationRaw = newValue.rawValue
                    }
                    
                } else {
                    // 権限オフ時は表示しない＋強制的にアプリ内のみ
                    EmptyView()
                        .onAppear { reminder.saveDestination = .appOnly }
                }
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
                editingReminder = reminder
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}
