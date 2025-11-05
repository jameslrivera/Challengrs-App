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
        if isSignUp {
            session.signUp(username: username, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        presentation.wrappedValue.dismiss()
                    case .failure(let err):
                        errorMsg = err.localizedDescription
                    }
                }
            }
        } else {
            session.signIn(username: username, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        presentation.wrappedValue.dismiss()
                    case .failure(let err):
                        errorMsg = err.localizedDescription
                    }
                }
            }
        }
    }
}
