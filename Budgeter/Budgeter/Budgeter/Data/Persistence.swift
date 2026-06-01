import CoreData

final class Persistence {
    static let shared  = Persistence()
    static let preview = Persistence(inMemory: true, seed: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false, seed: Bool = false) {

        //core data model reference
        container = NSPersistentContainer(name: "Budgeter")

        guard let desc = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description.")
        }

        if inMemory {
            desc.url = URL(fileURLWithPath: "/dev/null")
        }

        desc.shouldMigrateStoreAutomatically = true
        desc.shouldInferMappingModelAutomatically = true

        desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { storeDesc, error in
            if let error = error {
                if let url = storeDesc.url {
                    let psc = self.container.persistentStoreCoordinator
                    do {
                        try psc.destroyPersistentStore(at: url,
                                                       ofType: NSSQLiteStoreType,
                                                       options: nil)
                        try psc.addPersistentStore(ofType: NSSQLiteStoreType,
                                                   configurationName: nil,
                                                   at: url,
                                                   options: [
                                                    NSMigratePersistentStoresAutomaticallyOption: true,
                                                    NSInferMappingModelAutomaticallyOption: true
                                                   ])
                        print("⚠️ Destroyed incompatible store and recreated it at \(url.lastPathComponent)")
                    } catch {
                        fatalError("Failed to recover from migration error: \(error)")
                    }
                } else {
                    fatalError("Persistent store load error (no URL): \(error)")
                }
            }
        }

        let ctx = container.viewContext
        ctx.automaticallyMergesChangesFromParent = true
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if seed {
            let ctx = container.viewContext
            SeedData.seedIfNeeded(in: ctx)
            try? ctx.save()
        }
    }
}

//helps with saving
extension NSManagedObjectContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        do { try save() } catch { print("Core Data save error:", error) }
    }
}
