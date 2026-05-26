import Foundation
import SwiftData

/// Anchors the SwiftData store on `SchemaV1`. When a future version
/// changes any persistent property:
///   1. Snapshot the affected model into a new `SchemaVN` namespace
///   2. Append the new schema to `schemas`
///   3. Append a `.lightweight` or `.custom` stage to `stages`
enum CashFlowsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
