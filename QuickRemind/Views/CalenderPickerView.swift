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
                    ForEach(items, id: \.calendarIdentifier) { (cal: EKCalendar) in // ← ここ
                        Text("\(cal.title) ・ \(cal.source.title)")
                            .tag(cal.calendarIdentifier as String) // ← tagの型も明示
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("保存先カレンダー")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { onClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("選択") {
                        if let id = selectedCalendarID {
                            UserDefaults.standard.set(id, forKey: "qr_selectedCalendarID")
                        } else {
                            UserDefaults.standard.removeObject(forKey: "qr_selectedCalendarID")
                        }
                        onClose()
                    }
                }
            }
        }
    }
}