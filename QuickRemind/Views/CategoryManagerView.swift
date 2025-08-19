import SwiftUI

// MARK: - カテゴリ管理画面
struct CategoryManagerView: View {
    @Binding var reminders: [Reminder]
    @Binding var categories: [String]
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing: Bool = false
    @State private var newCategory: String = ""
    @State private var editedNames: [String] = []
    @State private var showHelp: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // 新規カテゴリーを追加する
                Section(header: Text("新規カテゴリーを追加")) {
                    HStack {
                        TextField("カテゴリー名", text: $newCategory)
                        Button("追加") {
                            guard !newCategory.isEmpty, !categories.contains(newCategory) else { return }
                            categories.append(newCategory)
                            newCategory = ""
                            editedNames = categories
                        }
                    }
                }
                
                // 既存カテゴリーを編集する
                Section(header: 
                            HStack {
                    Text("既存カテゴリー")
                    Spacer()
                    Button(action: {
                        showHelp = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                ) {
                    ForEach(categories.indices, id: \.self) { index in
                        if isEditing {
                            if index < editedNames.count {
                                TextField("カテゴリー名", text: $editedNames[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                Text(categories[index])
                            }
                        } else {
                            Text(categories[index])
                        } 
                    }
                    
                    .onDelete { indexSet in
                        categories.remove(atOffsets: indexSet)
                        editedNames = categories
                        if categories.isEmpty {
                            categories.append("カテゴリーなし")
                            editedNames = categories
                        }
                    }
                    .onMove { from, to in
                        categories.move(fromOffsets: from, toOffset: to)
                        editedNames = categories
                    }
                }
                
            }
            .onAppear {
                editedNames = categories
            }
            .navigationTitle("カテゴリー管理")
            .navigationBarItems(
                leading: Button("閉じる") { dismiss() },
                trailing: Button(isEditing ? "完了" : "編集") {
                    toggleEditing()
                }
            )  
            .alert("操作のヒント", isPresented: $showHelp) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("カテゴリーの削除：左にスワイプ\n並び替え：長押しでドラッグ")
            }
        }
    }
    
    // MARK: - カテゴリ名を変更し、リマインダーも更新
    private func commitRename(at index: Int) {
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
    private func toggleEditing() {
        if isEditing {
            applyEdits()
        }
        isEditing.toggle()
    }
    
    // 編集確定処理（名前変更＆リマインダーに反映）
    private func applyEdits() {
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
}
