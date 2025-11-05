//
//  ChallengrsApp.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI
// import Firebase // uncomment this later when you add Firebase SDK and GoogleService-Info.plist

@main
struct ChallengrsApp: App {
    // Use the mock/local SessionStore for now. We'll swap to FirebaseAuth later.
    @StateObject private var session = SessionStore.shared

    init() {
        // If/when you add Firebase, uncomment the import above and this line:
        // FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
