//
//  CurrentChallengesView.swift
//  Challengrs
//
//  Created by James Rivera on 11/6/25.
//

import Foundation

import SwiftUI

struct CurrentChallengesView: View {
    @EnvironmentObject var session: SessionStore
    @State private var challenges: [Challenge] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading challenges...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
            } else if challenges.isEmpty {
                Text("No current challenges. Create one!")
            } else {
                List(challenges) { challenge in
                    ChallengeRow(challenge: challenge)  // Your ChallengeRow.swift
                }
            }
        }
        .navigationTitle("Current Challenges")
        .onAppear {
            fetchChallenges()
        }
    }
    
    private func fetchChallenges() {
        guard let userId = session.currentUser?.id else {
            errorMessage = "Not logged in"
            isLoading = false
            return
        }
        
        FirestoreService.shared.fetchChallenges(for: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetched):
                    challenges = fetched
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}
