import SwiftUI

struct MinuteIntervalDatePicker: UIViewRepresentable {
    var date: Binding<Date>
    var minuteInterval: Int

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        // 1時間刻みの場合は60分刻みにして00分固定にする
        picker.minuteInterval = minuteInterval == 60 ? 60 : max(1, minuteInterval)
        picker.addTarget(context.coordinator,
                         action: #selector(Coordinator.changed(_:)),
                         for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if uiView.date != date.wrappedValue {
            uiView.date = date.wrappedValue
        }
        if uiView.minuteInterval != minuteInterval {
            uiView.minuteInterval = minuteInterval == 60 ? 60 : max(1, minuteInterval)
        }
        // CoordinatorのminuteIntervalも更新
        if let coordinator = context.coordinator as? Coordinator {
            coordinator.minuteInterval = minuteInterval
        }
    }

    func makeCoordinator() -> Coordinator { 
        let coordinator = Coordinator(date)
        coordinator.minuteInterval = minuteInterval
        return coordinator
    }

    final class Coordinator: NSObject {
        var date: Binding<Date>
        var minuteInterval: Int = 1
        
        init(_ date: Binding<Date>) { self.date = date }
        
        @objc func changed(_ sender: UIDatePicker) {
            date.wrappedValue = sender.date
        }
    }
}
