import SwiftUI
import EventKit

struct CalendarPickerView: View {
    let calendars: [EKCalendar]
    @Binding var selectedCalendarID: String?
    let onClose: () -> Void
    
    // 事前計算
    private var editableCalendars: [EKCalendar] {
        calendars.filter { $0.allowsContentModifications }
    }
    
    // Optionalを潰した selection
    private var selectionBinding: Binding<String> {
        Binding(
            get: { selectedCalendarID ?? "" },
            set: { selectedCalendarID = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 型を明示して推論を助ける
                let items: [EKCalendar] = editableCalendars
                Picker("保存先カレンダー", selection: selectionBinding) {
                    if items.isEmpty {
                        // 権限オフ or カレンダーなしのときにメッセージ表示
                        Text("保存可能なカレンダーがありません。\n権限がオフです。")
                    } else {
                        ForEach(items, id: \.calendarIdentifier) { cal in
                            Text("\(cal.title) ・ \(cal.source.title)")
                                .tag(cal.calendarIdentifier)
                        }
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("予定の保存先")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { onClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("選択") {
                        CalendarService.selectedCalendarIDInDefaults = selectedCalendarID
                        onClose()
                    }
                }
            }
        }
    }
}
