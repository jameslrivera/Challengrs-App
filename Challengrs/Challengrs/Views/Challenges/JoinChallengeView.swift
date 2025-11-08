//
//  JoinChallengeView.swift
//  Challengrs
//
//  Created by James Rivera on 11/8/25.
//

import Foundation
import SwiftUI

struct JoinChallengeView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var session: SessionStore
    @State private var inviteCode = ""
    @State private var frequency: Frequency = .daily
    @State private var goalDescription = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var joinedChallengeId: String? = nil  // For post-join navigation if needed

    var body: some View {
        NavigationView {
            Form {
                TextField("Enter Invite Code", text: $inviteCode)
                    .textInputAutocapitalization(.characters)  // For uppercase codes
                
                Picker("Your Upload Frequency", selection: $frequency) {
                    Text("Daily (30 uploads)").tag(Frequency.daily)
                    Text("Once a Week (4 uploads)").tag(Frequency.weekly)
                    Text("5 Times a Week (20 uploads)").tag(Frequency.fiveTimesAWeek)
                }
                .pickerStyle(.segmented)
                
                TextField("Your Goal (optional, e.g., 'daily workout pic')", text: $goalDescription)
                
                Section {
                    Button(action: joinChallenge) {
                        Text(isLoading ? "Joining..." : "Join Challenge")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || inviteCode.isEmpty)
                }
            }
            .navigationTitle("Join Challenge")
            .navigationBarItems(leading: Button("Cancel") { presentation.wrappedValue.dismiss() })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Join Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if joinedChallengeId != nil {
                            presentation.wrappedValue.dismiss()  // Auto-dismiss on success
                        }
                    }
                )
            }
        }
    }
    
    private func joinChallenge() {
        guard let userId = session.currentUser?.id else {
            alertMessage = "Not logged in. Please sign in."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Step 1: Join via code
        FirestoreService.shared.joinChallengeByInviteCode(inviteCode.uppercased(), userId: userId) { joinResult in
            DispatchQueue.main.async {
                switch joinResult {
                case .success:
                    // Step 2: Create and save user config
                    let config = ParticipantConfig(userId: userId, frequency: frequency, goalDescription: goalDescription.isEmpty ? nil : goalDescription)
                    // Note: You'll need to fetch challengeId after join; for now, assume we refetch or pass it
                    self.saveConfig(for: config) { configResult in
                        self.isLoading = false
                        if configResult {
                            self.joinedChallengeId = "fetched-id"  // Update with real ID from fetch
                            self.alertMessage = "Joined successfully! Your goal: \(frequency.rawValue.capitalized) uploads."
                        } else {
                            self.alertMessage = "Joined, but couldn't save your settings. Edit later."
                        }
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.isLoading = false
                    self.alertMessage = "Invalid code or join failed: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func saveConfig(for config: ParticipantConfig, completion: @escaping (Bool) -> Void) {
        // Placeholder: Fetch challenge ID after join, then update challenge's participantConfigs
        // In FirestoreService, add: func updateParticipantConfig(challengeId: String, config: ParticipantConfig, completion: @escaping (Bool) -> Void)
        // For now, simulate success
        completion(true)  // Replace with real call
    }
}
