import CoreData

class PersistenceController {
    
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        

        
//
//        let coffeeSet = ["Latte","Cappuccino","Americano","Mocha","Flat Black"]
//        let sizeSet = ["Small","Regular"]
//        let flavourSet = ["Vanilla","Hazelnut","Caramel","None"]
//        let milkSet = ["Whole","Skimmed","Semi Skimmed","Coconut","Almond","Soya"]
//
        for _ in 0..<10 {
            let newItem = Usercard(context: viewContext)
            newItem.id = UUID()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CashBackApp")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
   //     container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")

        container.loadPersistentStores (completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
