//
//  CountdownClockApp.swift
//  CountdownClock
//
//  Created by Admin on 1/31/23.
//

import SwiftUI

@main
struct CountdownClockApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PrototypeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(UIService())
        }
    }
}
