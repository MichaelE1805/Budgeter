import SwiftUI
import CoreData

struct ContentView: View {
    
    //Flag controlling whether Add Expense sheet is showing
    @State private var showAddExpense = false
    
    //App appearance preference
    @AppStorage("appearance") private var appearance: Int = 0

    var body: some View {
        TabView {
            NavigationStack {
                OverviewView(showAddExpense: $showAddExpense)
            }
            .tabItem{ Label("Overview", systemImage: "gauge") }
            
            NavigationStack {
                TransactionsView(showAddExpense: $showAddExpense)
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet") }

            NavigationStack {
                BudgetsView()
            }
            .tabItem { Label("Budgets", systemImage: "chart.pie") }
            
            NavigationStack {
                InsightsView()
            }
            .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .sheet(isPresented: $showAddExpense) { AddExpenseView() }
        
        //Controls the colour scheme
        .preferredColorScheme({
            switch appearance {
            case 1: return .light
            case 2: return .dark
            default: return nil
            }
        }())
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
}
