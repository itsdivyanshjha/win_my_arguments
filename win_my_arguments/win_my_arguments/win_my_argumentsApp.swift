//
//  win_my_argumentsApp.swift
//  win_my_arguments
//
//  Created by Divyansh Jha on 23/01/25.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct win_my_argumentsApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    let container: ModelContainer
    let logger = Logger(subsystem: "com.win_my_arguments", category: "app")
    
    init() {
        // Set the app to always use dark mode
        UserDefaults.standard.set(true, forKey: "AppleInterfaceStyle")
        
        logger.info("🚀 App initialization started")
        
        do {
            // Clear old data
            if let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: applicationSupportURL.appendingPathComponent("default.store"))
                logger.debug("Cleared old data store")
            }
            
            logger.debug("Creating schema...")
            let schema = Schema([
                Chat.self,
                Message.self
            ])
            logger.debug("Schema created with models: Chat and Message")
            
            logger.debug("Creating model configuration...")
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            logger.debug("Model configuration created")
            
            logger.debug("Attempting to create ModelContainer...")
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("✅ Container created successfully")
            
        } catch {
            logger.error("❌ Failed to create container: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .onAppear {
                            logger.info("📱 Main window appeared")
                        }
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .preferredColorScheme(.dark)
            .modelContainer(container)
        }
    }
}
