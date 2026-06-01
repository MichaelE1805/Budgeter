import SwiftUI
import CoreData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    //Core data for saving
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(entity: Category.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(entity: Account.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var accounts: FetchedResults<Account>

    
    @State private var amount: String = ""
    @State private var currency: String = "AUD"
    @State private var date = Date()
    @State private var merchant: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: Category? //Optional allows no selection
    @State private var selectedAccount: Account?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amount).keyboardType(.decimalPad) //Defaults amount to 0.00
                    TextField("Currency", text: $currency) //Gets saved currency format
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute]) //Lets user pick date + time
                }
                Section("Details") {
                    TextField("Merchant", text: $merchant) //Merchant name
                    TextField("Note (optional)", text: $note)   //Optional note
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { Text($0.name ?? "").tag(Optional($0)) }
                    }   //Which category from stored options expense is
                    Picker("Account", selection: $selectedAccount) {
                        ForEach(accounts) { Text($0.name ?? "").tag(Optional($0)) }
                    }   //Which account belongs to
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(Double(amount) == nil || selectedCategory == nil || selectedAccount == nil) //Disabled if these areas are nil
                }
            }
        }
        .onAppear {
            if selectedCategory == nil { selectedCategory = categories.first }
            if selectedAccount == nil { selectedAccount = accounts.first }
        }
    }
    
    //Saves data on sheet, creates a new expense
    private func save() {
        guard let amount = Double(amount) else { return }
        let e = Expense(context: context)
        e.id = UUID()
        e.amount = amount
        e.currency = currency
        e.date = date
        e.merchantName = merchant.isEmpty ? nil : merchant
        e.note = note.isEmpty ? nil : note
        e.category = selectedCategory
        e.account = selectedAccount
        do { try context.save(); dismiss() } catch { print("Save error:", error) }
    }
}
