import SwiftUI
import Charts   //Allows for charts
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var ctx //access core data
    
    //used for start and end of queries
    private static func monthBounds(for date: Date = .now) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }
    
    @FetchRequest private var expenses: FetchedResults<Expense>

    init() {
        let (start, end) = Self.monthBounds()
        _expenses = FetchRequest<Expense>(
            //sort chronologically
            sortDescriptors: [SortDescriptor(\.date, order: .forward)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Spend by Category")
                if categoryData.isEmpty {
                    //placeholder when no data
                    PlaceholderChart(height: 240)
                        .overlay(Text("No spending this month").foregroundStyle(.secondary))
                } else {
                    //creates horizontal bar chart
                    Chart(categoryData, id: \.name) {
                        BarMark(
                            x: .value("Amount", $0.total),
                            y: .value("Category", $0.name)
                        )
                    }
                    .frame(height: 240)
                    .padding(.horizontal, 8)
                }

                SectionHeader(title: "Trend Over Time")
                if dailyData.isEmpty {
                    //placeholder when no data
                    PlaceholderChart(height: 240)
                        .overlay(Text("No transactions to chart").foregroundStyle(.secondary))
                } else {
                    Chart(dailyData, id: \.day) {
                        AreaMark(
                            x: .value("Day", $0.day),
                            y: .value("Spent", $0.total)
                        )
                        LineMark(
                            x: .value("Day", $0.day),
                            y: .value("Spent", $0.total)
                        )
                    }
                    .frame(height: 240)
                    .padding(.horizontal, 8)
                }
            }
            .padding(16)
        }
        .navigationTitle("Insights")
    }
    
    private var categoryData: [(name: String, total: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category?.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Other" }
        return grouped
            .map { (name: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    //maps amount to days
    private var dailyData: [(day: Date, total: Double)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: expenses) { cal.startOfDay(for: $0.date ?? .now) }
        return grouped
            .map { (day: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.day < $1.day }
    }
}

struct PlaceholderChart: View {
    let height: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .frame(height: height)
            .overlay(Text("Chart Placeholder").foregroundStyle(.secondary))
    }
}

private extension String {
    var nilIfEmpty: String? { self.isEmpty ? nil : self }
}
