import Foundation

enum SalaryPeriod: String, Codable, CaseIterable, Identifiable, Sendable {
    case monthly
    case biweekly
    case oneOff = "one_off"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: "每月"
        case .biweekly: "每两周"
        case .oneOff: "一次性"
        }
    }
}
