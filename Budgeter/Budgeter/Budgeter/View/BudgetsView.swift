import SwiftUI
import CoreData

struct BudgetsView: View {
    //Access core data
    @Environment(\.managedObjectContext) private var ctx
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Budget.startDate, order: .reverse)]
    )


    private var budgets: FetchedResults<Budget>

    
    @State private var showCreate = false   //Controls create budget sheet
    @State private var refreshID = UUID()   //Forces list to re-render
    
    var body: some View {
        List {
            //For when there is no budget
            if budgets.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No budgets yet").foregroundStyle(.secondary)
                        Text("Tap + to create your first budget.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
            } else {
                //Show each budget with a progress spent bar
                ForEach(budgets) { b in
                    BudgetRow(budget: b, spent: spent(for: b))
                }
            }
        }
        .id(refreshID)  //Forces to rebuild to update
        .listStyle(.insetGrouped)
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateBudgetSheet()
        }
        
        //Updates when data changes
        .onReceive(NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: ctx
        )) { _ in
            refreshID = UUID()
        }
    }
    
    //Calculate amount spent
    private func spent(for b: Budget) -> Double {
        let req: NSFetchRequest<Expense> = Expense.fetchRequest()
        var preds: [NSPredicate] = []

        if let start = b.startDate { preds.append(NSPredicate(format: "date >= %@", start as NSDate)) }
        if let end   = b.endDate   { preds.append(NSPredicate(format: "date < %@", end as NSDate)) }
        
        if let name = b.name, !name.isEmpty, name != "Overall" {
            preds.append(NSPredicate(format: "category.name == %@", name))
        }

        if !preds.isEmpty { req.predicate = NSCompoundPredicate(type: .and, subpredicates: preds) }

        let items = (try? ctx.fetch(req)) ?? []
        return items.reduce(0) { $0 + $1.amount }
    }
    
    //Formatting helper
    private func fmt(_ x: Double, code: String) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
        return f.string(from: .init(value: x)) ?? "\(code) \(x)"
    }
    
    private func periodText(for b: Budget) -> String {
        let df = DateFormatter(); df.dateStyle = .medium
        switch (b.startDate, b.endDate) {
        case let (s?, e?):
            return "\(df.string(from: s)) – \(df.string(from: e))"
        case let (s?, nil):
            return "From \(df.string(from: s))"
        case let (nil, e?):
            return "Until \(df.string(from: e))"
        default:
            return "No dates"
        }
    }
    
    //Formatting for budget row
    @ViewBuilder
    private func BudgetRow(budget b: Budget, spent: Double) -> some View {
        let limit    = b.limit
        let currency = b.currency ?? "AUD"
        let left     = limit - spent

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(b.name ?? "Budget")
                    .font(.headline)
                Spacer()
                Text(periodText(for: b))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: limit > 0 ? min(spent / limit, 1) : 0)
            HStack {
                Text("Spent \(fmt(spent, code: currency)) of \(fmt(limit, code: currency))")
                Spacer()
                Text(left >= 0 ? "\(fmt(left, code: currency)) left" : "\(fmt(-left, code: currency)) over")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct CreateBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss             //to close the sheet
    @Environment(\.managedObjectContext) private var ctx    //core data

    //Fields for creating budget
    @State private var category: Category? = nil
    @State private var limit: String = ""
    @State private var currency: String = "AUD"
    @State private var start = Date()
    @State private var end = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

    // Pull categories from core data
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var categories: FetchedResults<Category>

    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $category) {
                    Text("(Overall)").tag(Optional<Category>(nil))
                    ForEach(categories) { c in
                        Text(c.name ?? "(Unnamed)").tag(Optional(c))
                    }
                }   //category to pick from
                TextField("Limit", text: $limit).keyboardType(.decimalPad)
                TextField("Currency", text: $currency)
                DatePicker("Start", selection: $start, displayedComponents: [.date])
                DatePicker("End", selection: $end, displayedComponents: [.date])
            }
            .navigationTitle("Create Budget")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(Double(limit) == nil) //disabled until limit parses
                }
            }
        }
    }
    
    //saves created budget
    private func save() {
        guard let lim = Double(limit) else { return }
        let b = Budget(context: ctx)
        b.id = UUID()
        b.name = category?.name ?? "Overall"
        b.limit = lim
        b.currency = currency
        b.startDate = start
        b.endDate = end

        do { try ctx.save(); dismiss() }
        catch { print("Failed to save budget:", error) }
    }
}
