//
//  ChangePassswordView.swift
//  Challengrs
//
//  Created by James Rivera on 11/6/25.
//

import Foundation
import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var session: SessionStore

    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var busy = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationView {
            Form {
                SecureField("Current password", text: $current)
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirm)

                if let e = errorMsg { Text(e).foregroundColor(.red) }

                Button(action: change) {
                    HStack { Spacer(); Text(busy ? "Working..." : "Change Password"); Spacer() }
                }.disabled(busy || newPassword != confirm)
            }
            .navigationTitle("Change Password")
        }
    }

    func change() {
        errorMsg = nil
        guard newPassword.count >= 10, newPassword.range(of: ".*[!@#$%^&*(),.?\":{}|<>\\[\\]\\\\/\\-=_+~`].*", options: .regularExpression) != nil else {
            errorMsg = "New password must be ≥10 chars and include a special character."
            return
        }
        busy = true
        session.changePassword(currentPassword: current, newPassword: newPassword) { err in
            DispatchQueue.main.async {
                busy = false
                if let e = err { errorMsg = e.localizedDescription }
                else { presentation.wrappedValue.dismiss() }
            }
        }
    }
}
