//
//  AuthView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct AuthView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject private var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = true
    @State private var errorMsg: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text(isSignUp ? "Create your account" : "Sign in")
                    .font(.title2).bold()
                    .padding(.top, 24)

                if isSignUp {
                    HStack {
                        TextField("First name", text: $firstName)
                            .autocapitalization(.words)
                        TextField("Last name", text: $lastName)
                            .autocapitalization(.words)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                }

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // email validation hint
                if !email.isEmpty && !isEmailValid(email) {
                    Text("Please enter a valid email address.")
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // live password hints
                VStack(alignment: .leading, spacing: 4) {
                    if !password.isEmpty && password.count < 10 {
                        Text("Password must be at least 10 characters.")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    if !password.isEmpty && !hasSpecialChar(password) {
                        Text("Password should include at least one special character.")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
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
                        .background(canSubmit() ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(!canSubmit())

                Button(action: {
                    isSignUp.toggle()
                    errorMsg = nil
                }) {
                    Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                        .font(.footnote)
                }
                .padding(.top, 6)

                Spacer()
            }
            .padding(.top, 8)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    // MARK: - Validation helpers
    private func hasSpecialChar(_ s: String) -> Bool {
        let set = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>[]\\/-=_+~`")
        return s.rangeOfCharacter(from: set) != nil
    }

    private func isEmailValid(_ s: String) -> Bool {
        // simple regex for basic validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return s.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func canSubmit() -> Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty && password.count >= 10 && hasSpecialChar(password) && isEmailValid(email)
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    // MARK: - Actions
    private func submit() {
        errorMsg = nil

        // Final client-side validation (set clear error messages)
        if !isEmailValid(email) {
            errorMsg = "Please enter a valid email address."
            return
        }
        if password.count < 10 {
            errorMsg = "Password must be at least 10 characters long."
            return
        }
        if !hasSpecialChar(password) {
            errorMsg = "Password must contain at least one special character (e.g. !@#$%)."
            return
        }

        if isSignUp {
            session.signUp(email: email, password: password, firstName: firstName, lastName: lastName) { err in
                DispatchQueue.main.async {
                    if let e = err {
                        // pass along Firebase error messages (they're helpful)
                        errorMsg = e.localizedDescription
                    } else {
                        // Optionally show a message telling user to check email for verification.
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        } else {
            session.signIn(email: email, password: password) { err in
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
