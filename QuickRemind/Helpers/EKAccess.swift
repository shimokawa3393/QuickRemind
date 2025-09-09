import EventKit

// 共通：アクセス状態を正規化
enum EKAccess {
    case none, writeOnly, full
    static func accessLevel(for entity: EKEntityType) -> EKAccess {
        switch EKEventStore.authorizationStatus(for: entity) {
        case .fullAccess: return .full
        case .authorized:  return .full        // iOS16以前 or カレンダーでの旧状態
        case .writeOnly:   return .writeOnly
        default:           return .none
        }
    }
}
