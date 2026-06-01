import SwiftUI
import CoreData

struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var context //Access core data
    @Binding var showAddExpense: Bool   //Controls sheet
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.date, order: .reverse)]
    ) private var expenses: FetchedResults<Expense>
    
    //used for filtering and searching
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                //search and Add
                HStack {
                    TextField("Search merchant or note", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                //category filter options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["All", "Groceries", "Dining Out", "Transport", "Bills", "Entertainment", "Other"], id: \.self) { cat in
                            FilterChip(label: cat, isSelected: cat == selectedFilter) {
                                selectedFilter = cat
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                //transaction list
                if filteredTxs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No transactions found")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredTxs) { tx in
                        TransactionRow(tx: tx)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
        }
    }
    
    private var filteredTxs: [Tx] {
        let allTxs = expenses.map { Tx(from: $0) }
        
        //Category filter
        let catFiltered = selectedFilter == "All"
            ? allTxs
            : allTxs.filter { $0.category == selectedFilter }
        
        //Search filter
        if searchText.isEmpty { return catFiltered }
        return catFiltered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct Tx: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let amount: Double
    let date: Date
    let currency: String
    
    init(from expense: Expense) {
        self.id = expense.id ?? UUID()
        self.name = expense.merchantName ?? "Unnamed"
        self.category = expense.category?.name ?? "Other"
        self.amount = expense.amount
        self.date = expense.date ?? Date()
        self.currency = expense.currency ?? "AUD"
    }
}

//how expenses are shown
struct TransactionRow: View {
    let tx: Tx
    
    var body: some View {
        HStack {
            //icon
            Image(systemName: icon(for: tx.category))
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            //merchant name + category
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.name)
                    .font(.headline)
                Text(tx.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            //amount and date
            VStack(alignment: .trailing) {
                Text(tx.amount, format: .currency(code: tx.currency))
                    .fontWeight(.semibold)
                Text(tx.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
}

//Reusable chip for filtering
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

//searching view
struct SearchChip: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
