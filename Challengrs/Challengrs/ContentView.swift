//
//  ContentView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            if session.currentUser == nil {
                SplashContainerView()
            } else {
                MainTabView()
            }
        }
        .animation(.default, value: session.currentUser != nil)
    }
}
