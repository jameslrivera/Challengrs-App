//
//  ChallengrsApp.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI
import Firebase

@main
struct ChallengrsApp: App {
    @StateObject private var session = SessionStore.shared

    init() {
        FirebaseApp.configure()
        
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
