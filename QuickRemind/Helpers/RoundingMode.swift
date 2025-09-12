import Foundation

// 設定値
enum MinuteGranularity: String, CaseIterable, Identifiable {
    case min1, min5, min15, min30, topOfHour   // 00固定
    var id: String { rawValue }

    /// UIDatePicker に渡す刻み幅
    var minuteInterval: Int {
        switch self {
        case .min1:   return 1
        case .min5:   return 5
        case .min15:  return 15
        case .min30:  return 30
        case .topOfHour: return 60   // 分は常に00だけ選べる
        }
    }
}

// モードはそのまま（recent/up/down）
enum RoundingMode {
    case nearest, up, down // 四捨五入、切り上げ、切り下げ
}


extension Date {
    // MARK: - 分単位で四捨五入する
    func rounded(toMinuteInterval minuteInterval: Int,
                 mode: RoundingMode,
                 calendar: Calendar = .current) -> Date { // カレンダーを指定する
        precondition(minuteInterval > 0 && minuteInterval <= 60) // 分単位が1~60の間であることを確認
        
        let base = calendar.date(bySetting: .second, value: 0, of: self) ?? self // 秒を0に設定
        let step = Double(minuteInterval * 60) 
        let quotient = base.timeIntervalSinceReferenceDate / step 
        let snapped: Double 
        switch mode {
        case .nearest: snapped = round(quotient) * step // 四捨五入
        case .up:      snapped = ceil(quotient)  * step // 切り上げ
        case .down:    snapped = floor(quotient) * step // 切り下げ
        }
        return Date(timeIntervalSinceReferenceDate: snapped) // 秒単位を日時に変換
    }
}
