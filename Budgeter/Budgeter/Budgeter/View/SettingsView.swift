import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var ctx    //access core data
    
    @State private var currency = AppSettings.preferredCurrency
    @AppStorage("appearance") private var appearance: Int = 0   // 0=System,1=Light,2=Dark
    @AppStorage("notificationsEnabled") private var notifications = true
    
    //controls display of reset pop-up
    @State private var confirmReset = false
    
    
    var body: some View {
        Form {
            Section("Profile & Data") {
                //changes preferred currency across whole program
                TextField("Preferred Currency", text: $currency)
                    .onChange(of: currency) { AppSettings.preferredCurrency = $0 }
                //display reset message
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset Data", systemImage: "arrow.counterclockwise")
                }
            }

            //displays options as a picker
            Section("App") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                Toggle("Notifications", isOn: $notifications)
            }
            //placeholder no functionality
            Section("About") {
                Button("Privacy Policy") {}
                Button("Licenses") {}
            }
        }
        .navigationTitle("Settings")
        
        //alert that prompts user confirming data to be deleted
        .alert("Reset demo data?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetData() }
        } message: {
            Text("This deletes all Expenses, Budgets, Accounts and Categories, then recreates starter data.")
        }
    }
    
    //wipes all saved data
    private func resetData() {
        func deleteAll<T: NSManagedObject>(_ fetch: NSFetchRequest<T>) {
            let objs = (try? ctx.fetch(fetch)) ?? []
            objs.forEach(ctx.delete)
        }
        deleteAll(Expense.fetchRequest())
        deleteAll(Budget.fetchRequest())
        deleteAll(Account.fetchRequest())
        deleteAll(Category.fetchRequest())

        ctx.saveIfNeeded()

        //Reseed categories and a default account
        SeedData.seedIfNeeded(in: ctx)
        ctx.saveIfNeeded()
    }
}
