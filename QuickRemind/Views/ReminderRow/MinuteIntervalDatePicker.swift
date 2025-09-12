import SwiftUI

struct MinuteIntervalDatePicker: UIViewRepresentable {
    var date: Binding<Date>
    var minuteInterval: Int

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = max(1, minuteInterval)
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
            uiView.minuteInterval = minuteInterval
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(date) }

    final class Coordinator: NSObject {
        var date: Binding<Date>
        init(_ date: Binding<Date>) { self.date = date }
        @objc func changed(_ sender: UIDatePicker) {
            date.wrappedValue = sender.date
        }
    }
}
