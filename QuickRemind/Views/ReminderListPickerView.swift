import SwiftUI
import EventKit

struct ReminderListPickerView: View {
    let lists: [EKCalendar]                      // .reminder 用のカレンダー（=リスト）
    @Binding var selectedReminderListID: String?         // 保存先リストID
    let onClose: () -> Void
    
    // 編集可能なリストだけ
    private var editableLists: [EKCalendar] {
        lists.filter { $0.allowsContentModifications }
    }
    
    // Optional を潰した selection
    private var selectionBinding: Binding<String> {
        Binding(
            get: { selectedReminderListID ?? "" },
            set: { selectedReminderListID = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                let items: [EKCalendar] = editableLists
                Picker("保存先リスト", selection: selectionBinding) {
                    if items.isEmpty {
                        Text("保存可能なリストがありません。\n権限がオフです。")
                    } else {
                        ForEach(items, id: \.calendarIdentifier) { (list: EKCalendar) in
                            Text("\(list.title) ・ \(list.source.title)")
                                .tag(list.calendarIdentifier)
                        }
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("リマインダーの保存先")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { onClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("選択") {
                        ReminderService.selectedReminderListIDInDefaults = selectedReminderListID
                        onClose()
                    }
                }
            }
        }
    }
}
