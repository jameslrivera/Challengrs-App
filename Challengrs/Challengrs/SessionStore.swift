//
//  SessionStore.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseAuth
import Combine

final class SessionStore: ObservableObject {
    static let shared = SessionStore()
    @Published var currentUser: SimpleUser?

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        listen()
    }

    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let s = self else { return }
            if let u = user {
                s.currentUser = SimpleUser(id: u.uid, username: u.email ?? u.uid)
            } else {
                s.currentUser = nil
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    deinit {
        if let h = handle { Auth.auth().removeStateDidChangeListener(h) }
    }
}
