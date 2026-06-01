//
//  BudgeterApp.swift
//  Budgeter
//
//  Created by Michael Elasi on 1/10/2025.
//

import SwiftUI

@main
struct BudgeterApp: App {
    let persistence = Persistence.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
