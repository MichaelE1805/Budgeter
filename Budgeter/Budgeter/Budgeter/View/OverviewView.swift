import SwiftUI
import CoreData

struct OverviewView: View {
    @Binding var showAddExpense: Bool
    @Environment(\.managedObjectContext) private var context //Access core data
    
    @State private var monthTotal: Double = 0
    @State private var monthNameStr: String = ""
    @State private var daysStr: String = ""
    @State private var topCats: [CategoryGrid.Item] = []
    
    //Fetches budgets from core data
    @FetchRequest(
        entity: Budget.entity(),
        sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: false)]
    ) private var budgets: FetchedResults<Budget>

    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                //Shows total expenditure and date
                HeaderCard(
                    total: monthTotal,
                    monthName: monthNameStr,
                    days: daysStr
                )
                
                //Shows budgets and their progress
                SectionHeader(title: "Budgets")
                if budgets.isEmpty {
                    Card { Text("No budgets yet").foregroundStyle(.secondary) }
                } else {
                    VStack(spacing: 12) {
                        ForEach(budgets) { b in
                            let spent = spent(for: b)
                            BudgetProgressCard(
                                title: b.name ?? "Budget",
                                subtitle: periodText(for: b),
                                spent: spent,
                                limit: b.limit,
                                currency: b.currency ?? "AUD"
                            )
                        }
                    }
                }

                //Shows what categories spending has been made in
                SectionHeader(title: "Top Categories")
                if topCats.isEmpty {
                    Card { Text("No spending yet this month").foregroundStyle(.secondary) }  
                } else {
                    CategoryGrid(categories: topCats)
                }
                
                //Create an expenditure
                SectionHeader(title: "Quick Actions")
                HStack(spacing: 12) {
                    PrimaryActionButton(title: "Add Expense", systemImage: "plus.circle.fill") {
                        showAddExpense = true
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Overview")
        .onAppear {
            SeedData.seedIfNeeded(in: context)
            refreshMonthTotals()
        }
        //Refreshes page ensuring expense amount updated
        .onChange(of: showAddExpense) { isShowing in
            if !isShowing { refreshMonthTotals() }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: context
        )) { _ in
            refreshMonthTotals()
        }

    }
    
    private func refreshMonthTotals() {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year,.month], from: Date()))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        
        //Fetches expenses
        let req: NSFetchRequest<Expense> = Expense.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        
        let items = (try? context.fetch(req)) ?? []
        
        monthTotal = items.reduce(0) { $0 + $1.amount }
        
        //Makes the categories
        var buckets: [String: Double] = [:]
        for e in items {
            let name = (e.category?.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Other"
            buckets[name, default: 0] += e.amount
        }
        
        
        let top = buckets.sorted { $0.value > $1.value }.prefix(4)
        topCats = top.map { CategoryGrid.Item(name: $0.key, amount: $0.value, icon: icon(for: $0.key)) }

        //Formats the date
        let df = DateFormatter(); df.dateFormat = "MMM yyyy"
        monthNameStr = df.string(from: start)
        
        //Shows the days progress e.g. 5 of 31
        let day = cal.component(.day, from: Date())
        let days = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        daysStr = "\(day) of \(days)"
    }
    
    //Spent aspect of budget view
    private func spent(for b: Budget) -> Double {
        let req: NSFetchRequest<Expense> = Expense.fetchRequest()
        var preds: [NSPredicate] = []

        if let start = b.startDate { preds.append(NSPredicate(format: "date >= %@", start as NSDate)) }
        if let end   = b.endDate   { preds.append(NSPredicate(format: "date < %@", end as NSDate)) }

        if let name = b.name, !name.isEmpty, name != "Overall" {
            preds.append(NSPredicate(format: "category.name == %@", name))
        }

        if !preds.isEmpty { req.predicate = NSCompoundPredicate(type: .and, subpredicates: preds) }
        let items = (try? context.fetch(req)) ?? []
        return items.reduce(0) { $0 + $1.amount }
    }
    
    //Shows the dates for the budget cards
    private func periodText(for b: Budget) -> String {
        let df = DateFormatter(); df.dateStyle = .medium
        switch (b.startDate, b.endDate) {
        case let (s?, e?): return "\(df.string(from: s)) – \(df.string(from: e))"
        case let (s?, nil): return "From \(df.string(from: s))"
        case let (nil, e?): return "Until \(df.string(from: e))"
        default: return "No dates"
        }
    }
}

struct HeaderCard: View {
    let total: Double
    let monthName: String
    let days: String

    var body: some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Month-to-date spend
                    Text(currency(total)).font(.largeTitle.bold())

                    // “Oct 2025 · 6 of 31”
                    Text("\(monthName) · \(days)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

//Budget cards format
struct BudgetProgressCard: View {
    let title: String
    var subtitle: String? = nil
    let spent: Double
    let limit: Double
    let currency: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.headline)
                    Spacer()
                    if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                }
                ProgressView(value: limit > 0 ? min(spent / limit, 1) : 0)
                HStack {
                    Text("Spent \(fmt(spent)) of \(fmt(limit))")
                    Spacer()
                    let left = limit - spent
                    Text(left >= 0 ? "\(fmt(left)) left" : "\(fmt(-left)) over")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }
    //Currency formatter
    private func fmt(_ x: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency
        return f.string(from: .init(value: x)) ?? "\(currency) \(x)"
    }
}


struct CategoryGrid: View {
    struct Item: Identifiable { let id = UUID(); let name: String; let amount: Double; let icon: String }
    let categories: [Item]
    let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(categories) { c in
                Card {
                    HStack {
                        Image(systemName: c.icon).font(.title3).frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.name).font(.subheadline.weight(.semibold))
                            Text(currency(c.amount)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

//Buttom format + use
struct PrimaryActionButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

//Lets category name be represented by a symbol
private func icon(for category: String) -> String {
    switch category {
    case "Groceries": return "cart"
    case "Dining Out": return "fork.knife"
    case "Transport": return "car"
    case "Bills": return "creditcard"
    case "Entertainment": return "gamecontroller"
    default: return "circle"
    }
}
