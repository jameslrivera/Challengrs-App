//
//  AuthView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct AuthView: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject private var session = SessionStore.shared

    @State private var username = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var errorMsg: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(isSignUp ? "Create your account" : "Sign in")
                    .font(.title2)
                    .bold()
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                if let e = errorMsg {
                    Text(e)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: submit) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(username.isEmpty || password.isEmpty)

                Button(action: { isSignUp.toggle(); errorMsg = nil }) {
                    Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                        .font(.footnote)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func submit() {
        errorMsg = nil
        // NOTE: SessionStore currently expects email:password:completion: so we pass username into email.
        // In future you can update UI to require a real email address, or change SessionStore to accept username.
        let emailToUse = username

        if isSignUp {
            session.signUp(email: emailToUse, password: password) { err in
                DispatchQueue.main.async {
                    if let e = err {
                        errorMsg = e.localizedDescription
                    } else {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        } else {
            session.signIn(email: emailToUse, password: password) { err in
                DispatchQueue.main.async {
                    if let e = err {
                        errorMsg = e.localizedDescription
                    } else {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

}
