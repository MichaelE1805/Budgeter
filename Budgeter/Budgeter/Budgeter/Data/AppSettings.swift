import Foundation

enum AppSettings {
    private static let seededKey = "hasSeeded"
    static var hasSeeded: Bool {
        get { UserDefaults.standard.bool(forKey: seededKey) }
        set { UserDefaults.standard.set(newValue, forKey: seededKey) }
    }

    
    static var preferredCurrency: String {
        get { UserDefaults.standard.string(forKey: "preferredCurrency") ?? "AUD" }
        set { UserDefaults.standard.set(newValue, forKey: "preferredCurrency") }
    }
}
