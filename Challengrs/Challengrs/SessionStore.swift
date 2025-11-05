//
//  SessionStore.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import Combine

final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var currentUser: SimpleUser? = nil

    private let userKey = "challengers_current_user"

    private init() {
        loadFromDefaults()
    }

    // MARK: - Mock auth (local, for dev)
    func signUp(username: String, password: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        // Simple uniqueness check stored in UserDefaults (dev-only)
        var users = Self.loadAllUsers()
        guard users[username] == nil else {
            completion(.failure(AuthError.usernameTaken))
            return
        }
        // store hashed password (we use a trivial hash here — replace server-side later)
        let hashed = Self.simpleHash(password)
        users[username] = hashed
        Self.saveAllUsers(users)
        let user = SimpleUser(id: UUID().uuidString, username: username)
        save(user: user)
        completion(.success(user))
    }

    func signIn(username: String, password: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        let users = Self.loadAllUsers()
        guard let stored = users[username] else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        let hashed = Self.simpleHash(password)
        guard stored == hashed else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        let user = SimpleUser(id: UUID().uuidString, username: username)
        save(user: user)
        completion(.success(user))
    }

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    // persistence of current user
    private func save(user: SimpleUser) {
        self.currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.setValue(data, forKey: userKey)
        }
    }

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(SimpleUser.self, from: data) {
            self.currentUser = user
        } else {
            self.currentUser = nil
        }
    }

    // MARK: - Simple local "user db" helpers (DEV ONLY)
    private static let usersKey = "challengers_local_users_v1"

    private static func loadAllUsers() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: usersKey) as? [String: String] ?? [:]
    }

    private static func saveAllUsers(_ dict: [String: String]) {
        UserDefaults.standard.setValue(dict, forKey: usersKey)
    }

    private static func simpleHash(_ s: String) -> String {
        // dev convenience only — replace with proper server-side hashing
        return String(s.reversed()) // trivial reversible "hash" for prototyping
    }

    enum AuthError: LocalizedError {
        case usernameTaken
        case invalidCredentials
        var errorDescription: String? {
            switch self {
            case .usernameTaken: return "That username is already taken."
            case .invalidCredentials: return "Invalid username or password."
            }
        }
    }
}
