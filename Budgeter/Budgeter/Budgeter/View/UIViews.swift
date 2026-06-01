import SwiftUI

//resuable display card
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

//Reusable header
struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
        }
        .padding(.top, 8)
    }
}

//formats amounts
func currency(_ x: Double, code: String = "AUD") -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
    return f.string(from: .init(value: x)) ?? "\(code) \(x)"
}
