//
//  CreateChallengeView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.presentationMode) var presentation
    @State private var name = ""
    @State private var description = ""
    @State private var stake = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var reminderTime = "20:00"
    @EnvironmentObject var session: SessionStore

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
                    Button("Create Challenge") {
                        createChallengeTapped()
                    }
                    .disabled(name.isEmpty || description.isEmpty || Double(stake) == nil)
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarItems(leading: Button("Cancel"){ presentation.wrappedValue.dismiss() })
        }
    }

    private func createChallengeTapped() {
        // Build Challenge model
        let stakeDouble = Double(stake) ?? 0.0
        let invite = generateInviteCode()
        let c = Challenge(name: name,
                          description: description,
                          stake: stakeDouble,
                          startDate: startDate,
                          endDate: endDate,
                          reminderTime: reminderTime,
                          participants: session.currentUser != nil ? [session.currentUser!.id] : [],
                          inviteCode: invite,
                          createdBy: session.currentUser?.id)
        // Use FirestoreService to save (call will be no-op if service not implemented yet)
        FirestoreService.shared.createChallenge(c) { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    presentation.wrappedValue.dismiss()
                }
            case .failure(let err):
                print("Create challenge error:", err.localizedDescription)
                // show an alert in a real app
            }
        }
    }

    private func generateInviteCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

