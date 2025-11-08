//
//  CreateChallengeView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//


import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var session: SessionStore
    @State private var name = ""
    @State private var description = ""
    @State private var stake = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var reminderTime = "20:00"
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var createdInviteCode: String? = nil
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basics")) {
                    TextField("Challenge name", text: $name)
                    TextField("Short description", text: $description)
                }
                Section(header: Text("Stake")) {
                    TextField("Amount per person (e.g. 5.00)", text: $stake)
                        .keyboardType(.decimalPad)
                    Text("Amount each participant will pay into the pot.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Section(header: Text("Schedule")) {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                    TextField("Reminder time (HH:mm)", text: $reminderTime)
                }
                Section {
                    Button(action: createChallengeTapped) {
                        Text(isLoading ? "Creating..." : "Create Challenge")
                    }
                    .disabled(isLoading || name.isEmpty || description.isEmpty || Double(stake) == nil)
                }
                
                if let code = createdInviteCode {
                    Section(header: Text("Invite Friends")) {
                        Text("Invite Code: \(code)")
                            .font(.subheadline)
                        Button("Share Invite Link") {
                            let shareText = "Join my challenge: \(name)! Use code: \(code)\nLink: challengrs://join?code=\(code)"
                            shareItems = [shareText]
                            showShareSheet = true
                        }
                    }
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarItems(leading: Button("Cancel"){ presentation.wrappedValue.dismiss() })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: shareItems)
            }
        }
    }
    
    private func createChallengeTapped() {
        guard let userId = session.currentUser?.id else {
            alertMessage = "User not logged in"
            showAlert = true
            return
        }
        
        guard let stakeDouble = Double(stake), stakeDouble > 0 else {
            alertMessage = "Invalid stake amount"
            showAlert = true
            return
        }
        
        if startDate >= endDate {
            alertMessage = "Start date must be before end date"
            showAlert = true
            return
        }
        
        isLoading = true
        
        let c = Challenge(
            name: name,
            description: description,
            stake: stakeDouble,
            startDate: startDate,
            endDate: endDate,
            reminderTime: reminderTime,
            participants: [userId],
            inviteCode: "",  // Let FirestoreService generate it
            createdBy: userId
        )
        
        FirestoreService.shared.createChallenge(c) { result in
            isLoading = false
            switch result {
            case .success(let docId):
                // Fetch the created challenge to get the inviteCode (since service generates it if empty)
                FirestoreService.shared.fetchChallenges(for: userId) { fetchResult in
                    switch fetchResult {
                    case .success(let challenges):
                        if let newChallenge = challenges.first(where: { $0.id == docId }) {
                            createdInviteCode = newChallenge.inviteCode
                        } else {
                            alertMessage = "Challenge created, but couldn't retrieve invite code"
                            showAlert = true
                        }
                    case .failure(let err):
                        print("Fetch error after create:", err.localizedDescription)
                        alertMessage = "Challenge created, but couldn't retrieve invite code: \(err.localizedDescription)"
                        showAlert = true
                    }
                }
                
            case .failure(let err):
                alertMessage = err.localizedDescription
                showAlert = true
            }
        }
    }
}

// Helper for share sheet (add to Utilities/ or here)
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
