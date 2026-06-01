import CoreData

struct SeedData {
    static func seedIfNeeded(in ctx: NSManagedObjectContext) {
        
        //Creates categories
        let catCount = (try? ctx.count(for: Category.fetchRequest())) ?? 0
        if catCount == 0 {
            ["Groceries", "Dining Out", "Transport", "Bills", "Entertainment", "Other"]
                .forEach { name in
                    let c = Category(context: ctx)
                    c.id = UUID()
                    c.name = name
                }
        }
        
        //Creates main account
        let accCount = (try? ctx.count(for: Account.fetchRequest())) ?? 0
        if accCount == 0 {
            let a = Account(context: ctx)
            a.id = UUID()
            a.name = "Main Account"
            a.type = "Everyday"
            a.startingBalance = 0
        }
        
        //Creates default expense
        let expenseCount = (try? ctx.count(for: Expense.fetchRequest())) ?? 0
        if expenseCount == 0 {
            let e = Expense(context: ctx)
            e.id = UUID()
            e.amount = 50
            e.currency = "AUD"
            e.date = Calendar.current.date(from: Calendar.current.dateComponents([.year,.month], from: Date()))
            e.merchantName = "Everyday"
            e.note = "Everyday"
        }
        
        //Creates default budget
        let budgetCount = (try? ctx.count(for: Budget.fetchRequest())) ?? 0
        if budgetCount == 0 {
            let b = Budget(context: ctx)
            b.id = UUID()
            b.name = "Overall"
            b.limit = 1500
            b.currency = "AUD"
            b.startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year,.month], from: Date()))
            b.endDate   = Calendar.current.date(byAdding: .month, value: 1, to: b.startDate!)
        }

        if ctx.hasChanges { try? ctx.save() }
    }
}
