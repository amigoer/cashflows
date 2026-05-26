import Foundation
import SwiftData

/// Baseline schema version. Every future change ships a new `SchemaVN`
/// snapshot of the affected models plus a `MigrationStage` from VN-1.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Salary.self,
            DebtPlan.self,
            Repayment.self,
            RecurringExpense.self,
        ]
    }
}
