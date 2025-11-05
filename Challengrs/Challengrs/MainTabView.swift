//
//  MainTabView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            CreatePlaceholderView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }

            CurrentChallengesView()
                .tabItem {
                    Label("Current", systemImage: "list.bullet")
                }
        }
    }
}
// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Hello, \(session.currentUser?.username ?? "—")")
                    .font(.title2)
                    .bold()

                Text("Balance (test): $0.00")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button(action: {
                        // future: edit profile action
                    }) {
                        Text("Edit Profile")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        session.signOut()
                    }) {
                        Text("Sign out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
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
