import SwiftUI

// MARK: - カテゴリ管理画面
struct CategoryView: View {
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
                        Image(systemName: "questionmark.circle")
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
                    CategoryService.toggleEditing(isEditing: &isEditing,
                                                  categories: &categories, reminders: &reminders,
                                                  editedNames: &editedNames)
                }
            )
            .alert("操作のヒント", isPresented: $showHelp) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("並び替え：長押しでドラッグ\nカテゴリーの削除：左にスワイプ")
            }
        }
    }
}
