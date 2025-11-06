//
//  EditProfileView.swift
//  Challengrs
//
//  Created by James Rivera on 11/6/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var session: SessionStore

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false
    @State private var msg: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("First", text: $firstName)
                    TextField("Last", text: $lastName)
                }

                if let m = msg {
                    Section { Text(m).foregroundColor(.red) }
                }

                Section {
                    Button(action: save) {
                        HStack { Spacer(); Text(isSaving ? "Saving..." : "Save"); Spacer() }
                    }.disabled(isSaving)
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                if let u = session.currentUser {
                    firstName = u.firstName
                    lastName = u.lastName
                }
            }
        }
    }

    func save() {
        isSaving = true
        session.updateProfile(firstName: firstName, lastName: lastName) { err in
            DispatchQueue.main.async {
                isSaving = false
                if let e = err { msg = e.localizedDescription }
                else { presentation.wrappedValue.dismiss() }
            }
        }
    }
}
