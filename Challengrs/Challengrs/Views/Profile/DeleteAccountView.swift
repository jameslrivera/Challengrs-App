//
//  DeleteAccountView.swift
//  Challengrs
//
//  Created by James Rivera on 11/6/25.
//

import Foundation
import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var session: SessionStore

    @State private var currentPassword = ""
    @State private var busy = false
    @State private var errorMsg: String?
    @State private var showConfirm = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Enter current password to delete your account", text: $currentPassword)
                }

                if let e = errorMsg { Section { Text(e).foregroundColor(.red) } }

                Section {
                    Button(role: .destructive, action: { showConfirm = true }) {
                        Text("Delete my account")
                    }
                    .disabled(busy || currentPassword.isEmpty)
                }
            }
            .navigationTitle("Delete Account")
            .confirmationDialog("Are you sure? This cannot be undone.", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Yes, delete my account", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func performDelete() {
        busy = true
        session.deleteAccount(currentPassword: currentPassword) { err in
            DispatchQueue.main.async {
                busy = false
                if let e = err { errorMsg = e.localizedDescription }
                else {
                    // Signed-out state will be reflected by auth listener; dismiss.
                    presentation.wrappedValue.dismiss()
                }
            }
        }
    }
}
