//
//  win_my_argumentsApp.swift
//  win_my_arguments
//
//  Created by Divyansh Jha on 23/01/25.
//

import SwiftUI
import SwiftData

@main
struct win_my_argumentsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
