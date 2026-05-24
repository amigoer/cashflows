import Foundation

enum RepaymentStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case paid
    case overdue

    var displayName: String {
        switch self {
        case .pending: "待还"
        case .paid: "已还"
        case .overdue: "逾期"
        }
    }
}
