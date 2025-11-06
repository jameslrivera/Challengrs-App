//
//  MainTabView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selection: Int = 1  // default selected tab (1 = Create)

    var body: some View {
        TabView(selection: $selection) {
            // LEFT — Current challenges (index 0)
            CurrentChallengesView()
                .tabItem {
                    Label("Current", systemImage: "list.bullet")
                }
                .tag(0)

            // CENTER — Create (index 1)
            CreatePlaceholderView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
                .tag(1)

            // RIGHT — Profile (index 2)
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .environmentObject(session)
    }
}
// ProfileView (sheet-based)
import SwiftUI

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore

    @State private var showEdit = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                VStack(spacing: 14) {
                    // Greeting / email
                    VStack(spacing: 6) {
                        Text("Hello, \(session.currentUser?.displayName ?? session.currentUser?.firstName ?? "—")")
                            .font(.title2)
                            .bold()
                        if let email = session.currentUser?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 20)

                    // Single-column uniform buttons
                    VStack(spacing: 12) {
                        Button(action: { showEdit = true }) {
                            Label("Edit Profile", systemImage: "pencil")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(UniformFilledButtonStyle())

                        Button(action: { showChangePassword = true }) {
                            Label("Change Password", systemImage: "key")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(UniformFilledButtonStyle())

                        Button(action: { showDeleteAccount = true }) {
                            Label("Delete Account", systemImage: "trash")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(UniformFilledButtonStyle())

                        Button(action: { _ = session.signOut() }) {
                            Label("Sign out", systemImage: "arrow.backward.circle")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(UniformFilledButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 420)
                .multilineTextAlignment(.center)

                Spacer()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEdit) {
                EditProfileView().environmentObject(session)
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView().environmentObject(session)
            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountView().environmentObject(session)
            }
        }
    }
}

/// A single, uniform filled button style used for all profile actions.
/// Uses the accent color, white text, rounded corners and a subtle scale on press.
struct UniformFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.92 : 1.0)
                    .shadow(color: Color.black.opacity(configuration.isPressed ? 0.06 : 0.12), radius: configuration.isPressed ? 1 : 4, x: 0, y: configuration.isPressed ? 0 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.995 : 1.0)
    }
}

// MARK: - CreatePlaceholderView
struct CreatePlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .foregroundColor(.blue.opacity(0.8))

                Text("Create a Challenge")
                    .font(.title2)
                    .bold()

                Text("Wire up the Create Challenge screen here. Add fields for name, description, stake, dates, and invite code.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    // future: open create challenge flow
                }) {
                    Text("Start a new challenge")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Create")
        }
    }
}

// MARK: - CurrentChallengesView
struct CurrentChallengesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Your Current Challenges")
                    .font(.title2)
                    .bold()

                Text("This list will show challenges you're participating in. Tap one to see details and submit proof.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Current")
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(SessionStore.shared)
    }
}
