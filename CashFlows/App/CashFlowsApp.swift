import SwiftData
import SwiftUI

@main
struct CashFlowsApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try ModelContainer(
                for: Schema(versionedSchema: SchemaV1.self),
                migrationPlan: CashFlowsMigrationPlan.self
            )
        } catch {
            fatalError("Failed to initialise ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
