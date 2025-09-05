import SwiftUI

enum CategoryService {
    
    // MARK: - カテゴリ名を変更し、リマインダーも更新
    static func commitRename(at index: Int,
                             categories: inout [String],
                             reminders: inout [Reminder],
                             editedNames: inout [String],
                             isEditing: inout Bool) {
        let oldName = categories[index]
        let newName = editedNames[index].trimmingCharacters(in: .whitespaces)
        
        guard !newName.isEmpty, !categories.contains(newName) else { return }
        
        categories[index] = newName
        reminders = reminders.map { reminder in
            if reminder.category == oldName {
                reminder.category = newName
            }
            return reminder
        }
        
        isEditing = false
        editedNames = categories
    }
    
    
    // 編集モードの切り替えと更新処理
    static func toggleEditing(isEditing: inout Bool,
                              categories: inout [String],
                              reminders: inout [Reminder],
                              editedNames: inout [String]) {
        if isEditing {
            applyEdits(categories: &categories, reminders: &reminders, editedNames: &editedNames)
        }
        isEditing.toggle()
    }
    
    
    // 編集確定処理（名前変更＆リマインダーに反映）
    static func applyEdits(categories: inout [String],
                           reminders: inout [Reminder],
                           editedNames: inout [String]) {
        for (index, oldName) in categories.enumerated() {
            let newName = editedNames[index].trimmingCharacters(in: .whitespaces)
            guard !newName.isEmpty, newName != oldName else { continue }
            
            // 重複はスキップ
            if editedNames.filter({ $0 == newName }).count > 1 { continue }
            
            // カテゴリ名更新
            categories[index] = newName
            
            // 関連リマインダー更新
            for reminder in reminders {
                if reminder.category == oldName {
                    reminder.category = newName
                }
            }
        }
        
        editedNames = categories
    }
    
    
    // MARK: - カテゴリーを保存する
    static func saveCategories(categories: [String]) {
        UserDefaults.standard.set(categories, forKey: "categories")
    }
    
    
    // MARK: - カテゴリーを読み込む
    static func loadCategories() -> [String] {
        if let saved = UserDefaults.standard.stringArray(forKey: "categories"), !saved.isEmpty {
            return saved
        } else {
            let defaultCategories = ["カテゴリーなし"]
            saveCategories(categories: defaultCategories)
            return defaultCategories
        }
    }
}
